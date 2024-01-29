import firebase_admin
from firebase_admin import credentials, auth, firestore
from flask import Flask, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

cred = credentials.Certificate("serviceAccount.json")
default_app = firebase_admin.initialize_app(cred)

db = firestore.client()

max_attempts = 3


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
                return {}, 202
            return {}, 200

        else:
            return {}, 404


@app.route("/test_print", methods=["POST"])
def test_print():
    page = auth.list_users()
    while page:
        for user in page.users:
            print("user: ", user.uid)
            print("email: ", user.email)
            print()
        page = page.get_next_page()
    return {}, 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5050)