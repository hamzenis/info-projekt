import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/stockData_service.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

/// TODO:
/// Function that starts the buy flow.
/// It checks if the user is logged in and if he is, it checks if the password he entered is correct.
/// If the password is correct, it checks if the user has enough money to buy the stock.
/// If the user has enough money, it subtracts the amount of money from the user's balance and adds the stock to his transaction history.
Future<void> startBuyStockFlow(
    BuildContext context, int amount, String stockSymbol) async {
  try {
    final user = _auth.currentUser;
    if (user != null) {
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
        final querySnapshot = await _firestore
            .collection('Users')
            .where('UID', isEqualTo: user.uid)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          // double price = (double.tryParse(await getCurrentPrice(stockSymbol)) * amount);
          String? priceString = await getCurrentPrice(stockSymbol);
          double price = double.tryParse(priceString ?? '0.0') ?? 0.0;
          double totalPrice = price * amount;

          await _firestore.collection('Users').doc(userDoc.id).update({
            'balance': FieldValue.increment(-totalPrice),
          });

          await _firestore
              .collection('Users')
              .doc(userDoc.id)
              .collection('transaction_history')
              .add({
            'amount': amount,
            'date_buy': Timestamp.now(),
            'date_sell': Timestamp.fromDate(DateTime(2000, 1, 1)),
            'price_buy': totalPrice,
            'owned': true,
            'price_sell': 0.0,
            'stock_symbol': stockSymbol,
          });
        }
      }
    }
  } on Exception catch (e) {
    print('Buy failed: $e');
  }
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
