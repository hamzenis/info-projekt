import firebase_admin
from firebase_admin import credentials, auth, firestore
from flask import Flask, render_template, request
from flask_cors import CORS

app = Flask(__name__, template_folder="template")
CORS(app)

cred = credentials.Certificate("serviceAccount.json")
default_app = firebase_admin.initialize_app(cred)

db = firestore.client()

max_attempts = 3

# Returns Completion Dialog Page and changes password
@app.route("/change_completed", methods=['POST', 'GET'])
def tester():
    data = request.get_json()
    uid = auth.get_user_by_email(data.get("email")).uid
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