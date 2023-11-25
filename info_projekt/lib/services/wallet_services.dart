// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// This is the Brain of the Wallet Screen.
/// This class works with the [WalletScreen] class to deposit and withdraw money.
/// This File have every functions that the Wallet Screen needs.
class WalletServices {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Function that was created for the withdraw button.
  /// It creates a popup with the amount of money that the user wants to withdraw and the IBAN of the user.
  /// It gets the IBAN of the user from the database and shows it to the user.
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

  /// Function that was created for the deposit button.
  /// It creates a popup only with the amount of money that the user wants to deposit.
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

  /// Function that was created for the withdraw button.
  /// It creates a popup with the password of the user.
  /// It acts as security feature, so that only the user that knows the password can withdraw money.
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

  /// Function that alerts the user via a popup that the withdraw amount is higher than the balance he have.
  void errorDialogWithdrawAmount(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: const Text('Insufficient balance'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ]);
        });
  }

  /// Function that alerts the user via a popup that the password he entered is incorrect.
  void errorDialogWrongPassword(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Incorrect password'),
            actions: [
              TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  })
            ],
          );
        });
  }

  /// This function starts the withdraw process.
  /// It checks if the user has enough money to withdraw the amount that he wants to withdraw.
  /// If the user has enough money, it checks if the password is correct.
  /// If the password is correct, it withdraws the money from the user and updates the balance in the database.
  /// It also adds the transaction to the balance history.
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
          errorDialogWithdrawAmount(context);
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
          errorDialogWrongPassword(context);
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

  /// This function starts the deposit process.
  /// It creates a payment intent and shows the payment sheet to the user.
  /// If the payment was successful, it updates the balance in the database.
  /// It also adds the transaction to the balance history.
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

  /// This function fetches the balance of the user from the database.
  /// It returns the balance as a double.
  /// If the user is not logged in, it returns null or
  /// If the user is logged in, but the balance is not in the database, it returns null.
  Future<double?> fetchBalance() async {
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
    return null;
  }
}
