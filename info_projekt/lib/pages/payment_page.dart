import 'package:flutter/material.dart';
import 'package:info_projekt/services/stripe_service.dart';

/// This class takes a [clientSecret] as a parameter.
/// The [clientSecret] is used to confirm card payments with the [StripeService].
/// This class allows the execution of the [StripeService] on web plattforms.
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
