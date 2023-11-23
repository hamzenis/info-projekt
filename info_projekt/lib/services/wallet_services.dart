// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
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
          title: const Text('Enter withdrawal amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your IBAN: $iban'),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
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
          title: const Text('Enter deposit amount'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Amount'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
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
          title: const Text('Enter your password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('OK'),
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
      final userData = userDoc.data();
      final balance = (userData['balance'] as num).toDouble();

      if (balance < amount) {
        if (kDebugMode) {
          print('Insufficient balance');
        }
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
          if (kDebugMode) {
            print('Incorrect password');
          }
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
        if (kDebugMode) {
          print('Failed to create payment intent: ${response.body}');
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print('Payment failed: $e');
      }
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
        final userData = userDoc.data();
        if (userData.containsKey('balance')) {
          final balance = (userData['balance'] as num).toDouble();
          return balance;
        }
      }
    }
    return 0.0;
  }
}
