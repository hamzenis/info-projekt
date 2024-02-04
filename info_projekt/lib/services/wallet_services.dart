// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/pages/profile_page.dart';
import 'package:info_projekt/widgets/password_input_widget.dart'; // Replace 'your_project' with your actual project name

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
              Text(
                  'Your IBAN: ${iban.length > 4 ? '****' + iban.substring(iban.length - 4) : iban}'),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*[,\.]?\d{0,2}')),
                ],
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
                double? amount =
                    double.tryParse(controller.text.replaceAll(',', '.'));
                if (amount == null || amount == 0) {
                  errorDialogInvalidInput(context);
                } else {
                  Navigator.of(context).pop(amount);
                }
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
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d*[,\.]?\d{0,2}'),
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
                double? amount = double.tryParse(
                  controller.text.replaceAll(',', '.'),
                );
                if (amount == null || amount == 0) {
                  errorDialogInvalidInput(context);
                } else if (amount < 10) {
                  errorDialogAmountTooSmall(context);
                } else if (amount > 999999.99) {
                  errorAmountToHigh(context);
                } else {
                  Navigator.of(context).pop(amount);
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Function that alerts the user via a popup that the amount he wants to deposit is too small.
  void errorDialogAmountTooSmall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invalid Input'),
          content: const Text('You can only deposit \$10 or more.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Function that alerts the user via a popup that the amount he wants to deposit is too high.
  void errorAmountToHigh(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Amount to high!'),
            content: const Text(
                'The maximum amount you can deposit is \$999,999.99'),
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

  /// Function that alerts the user via a popup that the input he entered is invalid.
  void errorDialogInvalidInput(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invalid Input'),
          content:
              const Text('Please enter a valid number like 1.0, 1, .90 or 1,0'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
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
  return showDialog<String>(
    context: context,
    builder: (context) {
      return PasswordDialog();
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

  /// Function that alerts the user that the input cant be zero.
  void errorDialogCantBeZero(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Amount cant be 0'),
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

  /// Function that alerts the user that he has to add an IBAN to his account before he can withdraw money.
  void errorDialogNoIbanFound(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('No IBAN found'),
            content: const Text(
                'You have to add an IBAN to your account before you can withdraw money.'),
            actions: [
              TextButton(
                child: const Text('Account Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(),
                    ),
                  );
                },
              ),
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
    /// the ip: 134.119.216.59 is the ip of the server
    /// if you want to run it on your local machine,
    /// you have to change the ip to localhost (ios) or 10.0.2.2 (android)
    var paymentIntentURL =
        Uri.parse("http://134.119.216.59:5000/create-payment-intent");

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

  /// DepositFlow for web
  /// This function starts the deposit process.
  /// It creates a payment intent and shows the payment sheet to the user.
  /// If the payment was successful, it starts a webhook from stripe to update the balance in the database.
  /// The database update is done via the backend server.
  /// It also adds the transaction to the balance history.
  Future<String?> startDepositFlowWeb(
      double depositAmount, String userId) async {
    int amountInCents = (depositAmount * 100).round();

    var response = await http.post(
      /// the ip: 134.119.216.59:5000 is the ip of the server
      /// cant be changed to localhost so easy, because the webhook from stripe cant reach the localhost
      /// if you want to run it on your local machine, you have to follow the instructions from stripe
      /// https://stripe.com/docs/connect/webhooks#test-webhooks-locally
      Uri.parse('http://134.119.216.59:5000/create-payment-intent-web'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'amount': amountInCents.toString(),
        'user_id': userId,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['url'];
    } else {
      if (kDebugMode) {
        print('Failed to create payment intent: ${response.body}');
      }
      return null;
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
