import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_braintree/flutter_braintree.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0.0;
  List<Transaction> _transactions = [];

  Future<void> startDepositFlow() async {
    // Request a client token from your server
    var clientTokenURL = Uri.parse("http://127.0.0.1:5000/client_token");
    var response = await http.get(clientTokenURL);
    var clientToken = jsonDecode(response.body)['clientToken'];

    // Start the Braintree payment flow
    var request = BraintreeDropInRequest(
      clientToken: clientToken,
      collectDeviceData: true,
      amount: '1.0',
    );
    var result = await BraintreeDropIn.start(request);

    // If the payment was successful, send the nonce to your server
    if (result != null) {
      var response = await http.post(
        Uri.parse('http://127.0.0.1:5000/checkout'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'payment_method_nonce': result.paymentMethodNonce.nonce,
          'amount': '1.0',
        }),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        if (result['result'] == 'success') {
          setState(() {
            if (request.amount != null) {
              _balance += double.parse(request.amount!);
              _transactions.add(Transaction(
                description: 'Deposit',
                amount: double.parse(request.amount!),
                date: DateTime.now(),
                type: TransactionType.deposit,
              ));
            }
          });
        } else {
          print('Transaction failed: ${result['message']}');
        }
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
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
                onPressed: startDepositFlow,
                child: Text('Deposit'),
              ),
            ],
          ),
          SizedBox(height: 16.0),
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_transactions[index].description),
                  subtitle: Text(_transactions[index].date.toString()),
                  trailing: Text(
                    '\$${_transactions[index].amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _transactions[index].type ==
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
