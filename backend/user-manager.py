import json
import firebase_admin
from firebase_admin import credentials, auth, firestore
from flask import Flask, render_template, request
from flask_cors import CORS
import requests

app = Flask(__name__, template_folder="template")
CORS(app)

cred = credentials.Certificate("serviceAccount.json")
default_app = firebase_admin.initialize_app(cred)

db = firestore.client()

FIREBASE_WEB_API_KEY = 'AIzaSyDlCgRwCCcNDs1pXRC3-e2yAp91mabh0cg' 


max_attempts = 3

# Returns Completion Dialog Page and changes password
# If password is the same as the old password, the password will not be changed
# and the user will be redirected to the same page with an error message
@app.route("/change_completed", methods=['POST', 'GET'])
def update_passsword_flow():
    data = request.get_json()
    uid = auth.get_user_by_email(data.get("email")).uid
    
    oldPasswordSameCheck = sign_in_with_email_and_password(data.get("email"), data.get("password"))
    
    # If in this json response, there is a field called "error", then the password is not the same as the old password
    # Check if the field 'error' is not in the Json response
    if "error" not in oldPasswordSameCheck:
        return render_template('change_password_same.html', email=data.get("email")), 200

    enable_user_account(data.get("email"))
    auth.update_user(
        uid=uid,
        password=data.get("password"),
    )
    print("Password Changed for ", data.get("email"))
    return render_template('change_password_confirmation.html', email=data.get("email")), 200


# Returns Change Password Form Page
@app.route("/reset", methods=['GET', 'POST'])
def reset_password():
    email = request.args.get('email')
    return render_template('change_password.html', args=email), 200

# Helper function to enable user account and set isDisabled to False
def enable_user_account(email):
    if email:
        userRequested = auth.get_user_by_email(email)
        if userRequested:
            users_ref = db.collection('Users')
            result = users_ref.where('UID', '==', userRequested.uid)
            users = result.stream()
        
            for user in users:
                users_ref = users_ref.document(user.id)
                users_ref.update({
                    "isDisabled": False,
                })
                auth.update_user(
                    userRequested.uid,
                    disabled=False,
                )
                return True
        else:
            False
        
        return False

    else:
        return False
    
    
# Helper function to sign in with email and password, because Firebase Admin SDK Python
# does not have a method to sign in with email and password
def sign_in_with_email_and_password(email, password, return_secure_token=True):
    payload = json.dumps({"email":email, "password":password, "return_secure_token":return_secure_token})
    rest_api_url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword"

    r = requests.post(rest_api_url,params={"key": FIREBASE_WEB_API_KEY}, data=payload)
    
    print("In Function")

    return r.json()


# Enables a user account if the user is disabled
@app.route("/enable", methods=['GET', 'POST'])
def enable_account():
    email = request.args.get('email')
    if email:
        userRequested = auth.get_user_by_email(email)
        if userRequested:
            users_ref = db.collection('Users')
            result = users_ref.where('UID', '==', userRequested.uid)
            users = result.stream()
        
            for user in users:
                users_ref = users_ref.document(user.id)
                users_ref.update({
                    "isDisabled": False,
                })
                auth.update_user(
                    userRequested.uid,
                    disabled=False,
                )
                return render_template('change_password_confirmation.html', email=email)
        else:
            return {}, 404
        
        return {}, 404

    else:
        return {}, 404

# Disables a user account if the counter is greater than or equal to the max attempts
# If the user is disabled, the user will be logged out
# If the user is not disabled, the counter will be incremented
@app.route("/wrong_password", methods=["POST"])
def wrong_password():
    data = request.get_json()
    emailRequested = data.get("email")
    userRequested = auth.get_user_by_email(emailRequested)
    
    if userRequested:

        users_ref = db.collection('Users')
        result = users_ref.where('UID', '==', userRequested.uid)
        users = result.stream()
        
        for user in users:
            users_ref = users_ref.document(user.id)
            disableCounter = user.to_dict().get("disableCounter")
            disableCounter += 1
            users_ref.update({
                "disableCounter": disableCounter
            })
            if disableCounter >= max_attempts:
                auth.update_user(
                    userRequested.uid,
                    disabled=True,
                )
                users_ref.update({
                    "isDisabled": True
                })
                auth.revoke_refresh_tokens(userRequested.uid)
                return {}, 202
            return {}, 200

        else:
            return {}, 404
        
        


# Debug route to print all users
@app.route("/test_print", methods=["POST, GET"])
def test_print():
    page = auth.list_users()
    while page:
        for user in page.users:
            print("user: ", user.uid)
            print("email: ", user.email)
            print()
        page = page.get_next_page()
    return {}, 200


# Main function
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5050)