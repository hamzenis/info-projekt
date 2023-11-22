import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<double?> getUserWithdrawInput(String iban) async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter withdrawal amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your IBAN: $iban'),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: 'Amount'),
              ),
            ],
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

  Future<String?> getUserPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter your password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(hintText: 'Password'),
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
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> startWithdrawFlow(double amount) async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('UID', isEqualTo: user.uid)
          .get();
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data() as Map<String, dynamic>;
      final balance = (userData['balance'] as num).toDouble();

      if (balance < amount) {
        print('Insufficient balance');
        return;
      }

      String? password = await getUserPassword();
      if (password != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        try {
          await user.reauthenticateWithCredential(credential);
        } catch (e) {
          print('Incorrect password');
          return;
        }

        await _firestore.collection('Users').doc(userDoc.id).update({
          'balance': FieldValue.increment(-amount),
        });
        await _firestore
            .collection('Users')
            .doc(userDoc.id)
            .collection('balance_history')
            .add({
          'amount': amount,
          'date': Timestamp.now(),
          'description': 'Withdraw',
          'withdraw': true,
        });
      }
    }
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

      final user = _auth.currentUser;
      if (user != null) {
        final querySnapshot = await _firestore
            .collection('Users')
            .where('UID', isEqualTo: user.uid)
            .get();
        final userDoc = querySnapshot.docs.first;

        await _firestore.collection('Users').doc(userDoc.id).update({
          'balance': FieldValue.increment(amount),
        });
        await _firestore
            .collection('Users')
            .doc(userDoc.id)
            .collection('balance_history')
            .add({
          'amount': amount,
          'date': Timestamp.now(),
          'description': 'Deposit',
          'withdraw': false,
        });
      }
    } on Exception catch (e) {
      print('Payment failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('User UID: ${_auth.currentUser?.uid}');
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('Users')
          .where('UID', isEqualTo: _auth.currentUser?.uid)
          .get(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No data');
        }
        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final balance = (data['balance'] as num).toDouble();
        return Scaffold(
          appBar: AppBar(
            title: Text('My Wallet'),
          ),
          body: Column(
            children: [
              SizedBox(height: 16.0),
              Text(
                'Balance: \$${balance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 24.0),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final user = _auth.currentUser;
                      if (user != null) {
                        final querySnapshot = await _firestore
                            .collection('Users')
                            .where('UID', isEqualTo: user.uid)
                            .get();
                        final userDoc = querySnapshot.docs.first;
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final iban = userData['iban'] as String;

                        double? withdrawAmount =
                            await getUserWithdrawInput(iban);
                        if (withdrawAmount != null) {
                          await Future.delayed(Duration(milliseconds: 500));
                          await startWithdrawFlow(withdrawAmount);
                        }
                      }
                    },
                    child: Text('Withdraw'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      double? depositAmount = await getUserInput();
                      if (depositAmount != null) {
                        await Future.delayed(Duration(milliseconds: 500));
                        await startDepositFlow(depositAmount);
                      }
                    },
                    child: Text('Deposit'),
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: _firestore
                      .collection('Users')
                      .where('UID', isEqualTo: _auth.currentUser?.uid)
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!userSnapshot.hasData ||
                        userSnapshot.data!.docs.isEmpty) {
                      return Text('No user data');
                    }
                    final userDoc = userSnapshot.data!.docs.first;
                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('Users')
                          .doc(userDoc.id)
                          .collection('balance_history')
                          .snapshots(),
                      builder: (BuildContext context,
                          AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData) {
                          return Text('No transactions');
                        }
                        final transactions = snapshot.data!.docs
                            .map((doc) => Transaction.fromFirestore(doc))
                            .toList();
                        return ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (BuildContext context, int index) {
                            var reversedTransactions =
                                transactions.reversed.toList();
                            return ListTile(
                              title:
                                  Text(reversedTransactions[index].description),
                              subtitle: Text(
                                  reversedTransactions[index].date.toString()),
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
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum TransactionType { deposit, withdrawal }

class Transaction {
  final double amount;
  final DateTime date;
  final String description;
  final TransactionType type;

  Transaction({
    required this.amount,
    required this.date,
    required this.description,
    required this.type,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final amount = (data['amount'] as num).toDouble();
    final date = (data['date'] as Timestamp).toDate();
    final description = data['description'] as String;
    final type = data['type'] == 'withdrawal'
        ? TransactionType.withdrawal
        : TransactionType.deposit;

    return Transaction(
      amount: amount,
      date: date,
      description: description,
      type: type,
    );
  }
}
