import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/services/stockData_service.dart';
import 'package:info_projekt/services/transaction_buy_service.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

/// TODO: Check total price calculation & wrong password handling
/// Function that starts the sell flow.
/// It checks if the user is logged in and if he is, it checks if the password he entered is correct.
/// If the password is correct, it checks if the user has the stock and enough amount to sell.
/// If the user has the stock and enough amount, it adds the amount of money to the user's balance and updates his transaction history.
Future<void> startSellStockFlow(
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

        // Get user document
        final userDoc = await _firestore.collection('Users').doc(user.uid).get();

        if (userDoc.exists) {
          // Query user's transaction history for the specific stock
          final transactionHistorySnapshot = await _firestore
              .collection('Users')
              .doc(user.uid)
              .collection('transaction_history')
              .where('stock_symbol', isEqualTo: stockSymbol)
              .where('owned', isEqualTo: true)
              .get();

          if (transactionHistorySnapshot.docs.isNotEmpty) {
            var transactionDoc = transactionHistorySnapshot.docs.first;
            int ownedAmount = transactionDoc['amount'];

            if (ownedAmount >= amount) {
  String? priceString = await getCurrentPrice(stockSymbol);
  double price = double.tryParse(priceString ?? '0.0') ?? 0.0;
  double totalPrice = price * amount;

  await _firestore.collection('Users').doc(user.uid).update({
    'balance': FieldValue.increment(totalPrice),
  });

  // Retrieve the original buying price
  double originalPriceBuy = transactionDoc.data()?['price_buy'] ?? 0.0;
  Timestamp originalDateBuy = transactionDoc.data()?['date_buy'] ?? Timestamp.now();

  // Update transaction history
  if (ownedAmount == amount) {
    await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('transaction_history')
        .doc(transactionDoc.id)
        .delete();
  } else {
    // Update transaction history for partial sell
    await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('transaction_history')
        .doc(transactionDoc.id)
        .update({
      'amount': FieldValue.increment(-amount),
      'date_buy': originalDateBuy,  // Use the original purchase date
      'date_sell': Timestamp.now(),
      'price_sell': totalPrice,
      'owned': false,
      'price_buy': originalPriceBuy,
      'stock_symbol': stockSymbol,
    });

          }
        } else {
          errorDialogNotEnoughShares(context);
        }
          } else {
            errorDialogNotEnoughShares(context);
          }
        }
      }
    }
  } on Exception catch (e) {
    print('Sell failed: $e');
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


void errorDialogNotEnoughShares(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Insufficient Shares'),
          content: const Text('You do not own enough shares to sell.'),
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