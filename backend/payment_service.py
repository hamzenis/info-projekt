from flask import Flask, request
from flask_cors import CORS
import stripe
import firebase_admin
from firebase_admin import credentials, firestore

app = Flask(__name__)
CORS(app)

cred = credentials.Certificate('serviceAccount.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

stripe.api_key = "sk_test_51OCfrgEFCGzXnEeOkDMh5AQmfgV1Q94pGy4DHIWu5hDcI03qXIlmX9Vmw3ULYp57yg8EGDqHml2fIe2RBZXtSqRD00s4Z5nD0I"

@app.route("/create-payment-intent", methods=["POST"])
def create_payment_intent():
    try:
        data = request.get_json()
        amount = data.get('amount', 1000)  
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency='usd',
        )
        return {"paymentIntent": payment_intent.client_secret}
    except Exception as e:
        return {"error": str(e)}

@app.route("/create-payment-intent-web", methods=["POST"])
def create_payment_intent_web():
    try:
        data = request.get_json()
        amount = data.get('amount', 1000)  
        user_id = data.get('user_id') 

        product = stripe.Product.create(name='My Product')
        price = stripe.Price.create(
            product=product.id,
            unit_amount=amount,
            currency='usd',
        )
        session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[{
                'price': price.id,
                'quantity': 1,
            }],
            mode='payment',
            success_url='http://localhost:8080/#/payment-success',
            cancel_url='http://localhost:8080/#/payment-cancel',
            client_reference_id=user_id,
        )
        return {"url": session.url}
    except Exception as e:
        return {"error": str(e)}
    
@app.route("/stripe-webhook", methods=["POST"])
def stripe_webhook():
    payload = request.get_data(as_text=True)
    sig_header = request.headers.get('Stripe-Signature')
    endpoint_secret = "whsec_EQ7GiesPTjGIo0OI1onMGuhSwVlZ09OD"

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, endpoint_secret
        )
    except ValueError as e:
        return {}, 400
    except stripe.error.SignatureVerificationError as e:
        return {}, 400

    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        user_id = session['client_reference_id']
        amount = session['amount_total'] / 100 

        users_ref = db.collection('Users')
        query = users_ref.where('UID', '==', user_id)
        users = query.stream()

        for user in users:
            user_ref = users_ref.document(user.id)
            new_balance = user.to_dict().get('balance', 0) + amount
            user_ref.update({'balance': new_balance})

            balance_history_ref = user_ref.collection('balance_history')
            balance_history_ref.add({
                'amount': amount,
                'date': firestore.SERVER_TIMESTAMP,
                'description': 'Deposit',
                'withdraw': False
            })
            break  

    return {}, 200



if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)