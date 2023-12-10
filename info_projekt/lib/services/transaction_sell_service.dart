import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/services/stockData_service.dart';
import 'package:info_projekt/services/transaction_buy_service.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

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

        // Fetch the user's transaction history
        final transactionHistorySnapshot = await _firestore
            .collection('Users')
            .doc(user.uid)
            .collection('transaction_history')
            .where('stock_symbol', isEqualTo: stockSymbol)
            .where('owned', isEqualTo: true)
            .get();

        int totalOwnedShares = 0;
        String documentId = ''; // Placeholder for the document ID
        for (var doc in transactionHistorySnapshot.docs) {
          totalOwnedShares += doc.data()['amount'] as int;
          documentId = doc.id; // Assuming the latest transaction is the target
        }

        if (amount > totalOwnedShares) {
          errorDialogNotEnoughShares(context);
          return;
        }

        String? priceString = await getCurrentPrice(stockSymbol);
        double price = double.tryParse(priceString ?? '0.0') ?? 0.0;
        double totalPrice = price * amount;

        // Update the user's balance
        await _firestore.collection('Users').doc(user.uid).update({
          'balance': FieldValue.increment(totalPrice),
        });

        // Update the transaction history
        if (amount >= totalOwnedShares) {
          // Selling all shares
          await _firestore.collection('Users').doc(user.uid).collection('transaction_history').doc(documentId).update({
            'owned': false,
            'date_sell': Timestamp.now(),
            'price_sell': totalPrice,
          });
        } else {
          // Partial selling, update the amount
          await _firestore.collection('Users').doc(user.uid).collection('transaction_history').doc(documentId).update({
            'amount': FieldValue.increment(-amount),
          });
        }
      }
    }
  } on Exception catch (e) {
    print('Sell failed: $e');
  }
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