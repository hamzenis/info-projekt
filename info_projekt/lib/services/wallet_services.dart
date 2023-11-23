import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletServices {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<double?> getUserWithdrawInput(
      BuildContext context, String iban) async {
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

  Future<double?> getUserInput(BuildContext context) async {
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

  Future<String?> getUserPassword(BuildContext context) async {
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

  Future<void> startWithdrawFlow(BuildContext context, double amount) async {
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

      String? password = await getUserPassword(context);
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

      if (response.statusCode == 200) {
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
          if (querySnapshot.docs.isNotEmpty) {
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
        }
      } else {
        print('Failed to create payment intent: ${response.body}');
      }
    } on Exception catch (e) {
      print('Payment failed: $e');
    }
  }

  Future<double> fetchBalance() async {
    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('UID', isEqualTo: user.uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData.containsKey('balance')) {
          final balance = (userData['balance'] as num).toDouble();
          return balance;
        }
      }
    }
    return 0.0;
  }
}
