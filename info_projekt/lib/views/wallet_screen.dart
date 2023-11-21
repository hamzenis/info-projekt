import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0.0;
  List<Transaction> _transactions = [];

  Future<double?> getUserInput() async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter deposit amount'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Amount'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                double? amount = double.tryParse(controller.text);
                Navigator.of(context).pop(amount);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> startDepositFlow(double amount) async {
    var paymentIntentURL =
        Uri.parse("http://localhost:5000/create-payment-intent");

    // Convert the amount from dollars to cents
    int amountInCents = (amount * 100).round();

    try {
      var response = await http.post(
        paymentIntentURL,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amountInCents}),
      );

      var jsonResponse = jsonDecode(response.body);
      var paymentIntentClientSecret = jsonResponse['paymentIntent'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: 'TradeMate',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      setState(() {
        _balance += amount;
        _transactions.add(Transaction(
          description: 'Deposit',
          amount: amount,
          date: DateTime.now(),
          type: TransactionType.deposit,
        ));
      });
    } on Exception catch (e) {
      print('Payment failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wallet'),
      ),
      body: Column(
        children: [
          SizedBox(height: 16.0),
          Text(
            'Balance: \$${_balance.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 24.0),
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement withdraw money functionality
                },
                child: Text('Withdraw'),
              ),
              ElevatedButton(
                onPressed: () async {
                  double? depositAmount = await getUserInput();
                  if (depositAmount != null) {
                    await startDepositFlow(depositAmount);
                  }
                },
                child: Text('Deposit'),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (BuildContext context, int index) {
                var reversedTransactions = _transactions.reversed.toList();

                return ListTile(
                  title: Text(reversedTransactions[index].description),
                  subtitle: Text(reversedTransactions[index].date.toString()),
                  trailing: Text(
                    '\$${reversedTransactions[index].amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: reversedTransactions[index].type ==
                              TransactionType.withdrawal
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Transaction {
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;

  Transaction({
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });
}

enum TransactionType {
  withdrawal,
  deposit,
}
