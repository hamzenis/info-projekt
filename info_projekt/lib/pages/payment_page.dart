import 'package:flutter/material.dart';
import 'package:info_projekt/services/stripe_service.dart';

class PaymentPage extends StatefulWidget {
  final String? clientSecret;

  const PaymentPage({Key? key, this.clientSecret}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late StripeService stripeService;

  @override
  void initState() {
    super.initState();
    stripeService = getStripeService();
    stripeService.confirmCardPayment(widget.clientSecret);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Page'),
      ),
      body: Center(
        child: Text('Client Secret: ${widget.clientSecret}'),
      ),
    );
  }
}
