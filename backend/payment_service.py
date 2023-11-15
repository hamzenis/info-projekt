from flask import Flask, request
import braintree

app = Flask(__name__)

gateway = braintree.BraintreeGateway(
    braintree.Configuration(
        braintree.Environment.Sandbox,
        merchant_id="xj464bssjbsr4nfv",
        public_key="4z7yc5qmwb43p83z",
        private_key="ec2c63ae8a1de165bafe4eb36fc8a997"
    )
)

@app.route("/client_token", methods=["GET"])
def client_token():
    return {"clientToken": gateway.client_token.generate()}

@app.route("/checkout", methods=["POST"])
def create_purchase():
    nonce_from_the_client = request.json.get("payment_method_nonce")
    amount = request.json.get("amount")
    result = gateway.transaction.sale({
        "amount": amount,
        "payment_method_nonce": nonce_from_the_client,
        "options": {
            "submit_for_settlement": True
        }
    })

    if result.is_success:
        return {"result": "success"}, 200
    else:
        return {"result": "error", "message": result.message}, 400

if __name__ == "__main__":
    app.run(port=5000)