from flask import Flask, request
import stripe

app = Flask(__name__)

stripe.api_key = "sk_test_51OCfrgEFCGzXnEeOkDMh5AQmfgV1Q94pGy4DHIWu5hDcI03qXIlmX9Vmw3ULYp57yg8EGDqHml2fIe2RBZXtSqRD00s4Z5nD0I"

@app.route("/create-payment-intent", methods=["POST"])
def create_payment_intent():
    try:
        data = request.get_json()
        amount = data.get('amount', 1000)  # default to 1000 if not provided
        payment_intent = stripe.PaymentIntent.create(
            amount=amount,
            currency='usd',
        )
        return {"paymentIntent": payment_intent.client_secret}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    app.run(port=5000)
