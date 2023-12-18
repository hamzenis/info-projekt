import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/services/stockData_service.dart';
import 'package:info_projekt/services/transaction_buy_service.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

/// TODO: Wrong password handling, taxes & fees
/// Function that starts the sell flow.
/// It checks if the user is logged in and if he is, it checks if the password he entered is correct.
/// If the password is correct, it checks if the user has the stock and enough amount to sell.
/// If the user has the stock and enough amount, it adds the amount of money to the user's balance and updates his transaction history.
Future<bool> startSellStockFlow(
    BuildContext context, int amount, String stockSymbol) async {
  try {
    final user = _auth.currentUser;
    if (user != null) {
      // final credential = EmailAuthProvider.credential(
      //   email: user.email!,
      //   password: password,
      // );
      // try {
      //   await user.reauthenticateWithCredential(credential);
      // } catch (e) {
      //   errorDialogWrongPassword(context); // TODO: FIX this
      //   return;
      // }
      String? password = await getUserPassword(context);
      if (password != null) {
        final querySnapshot = await _firestore
            .collection('Users')
            .where('UID', isEqualTo: user.uid)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          final stockSnapshot = await _firestore
              .collection('Users')
              .doc(userDoc.id)
              .collection('portfolio')
              .where('symbol', isEqualTo: stockSymbol)
              // Indexes in Firestore needed: Cloud Firestore -> Database -> Indexes -> Add Index or just click on the error message in the console if you get one
              .orderBy('purchaseDate', descending: false)
              .get();

          if (stockSnapshot.docs.isNotEmpty) {
            int sellQuantity = amount;
            int totalStocks = 0;
            List<int> updateStockQuantity = [];
            for (final stock in stockSnapshot.docs) {
              // Sell Logic:
              // If the amount of stocks to sell is smaller/same than the total amount of stocks, sell the amount of stocks
              // If the amount of stocks to sell is bigger than the total amount of stocks, error message
              totalStocks += int.tryParse(stock['quantity'].toString()) ?? 0;
            }
            for (final stock in stockSnapshot.docs) {
              if (sellQuantity <= totalStocks) {
                int individualStockQuantity =
                    int.tryParse(stock['quantity'].toString()) ?? 0;
                // Compare the individual stock quantity with the amount of stocks to sell
                // FIFO: First in, first out. If the amount of stocks to sell is smaller/same than the individual stock quantity
                // Than add to list and set the amount of stocks to sell to 0
                if (sellQuantity <= individualStockQuantity) {
                  updateStockQuantity
                      .add(individualStockQuantity - sellQuantity);
                  sellQuantity = 0;
                  // If the amount of stocks to sell is bigger than the individual stock quantity
                  // Than add 0 to list and subtract the individual stock quantity from the amount of stocks to sell
                  // For the next iteration
                } else if (sellQuantity > individualStockQuantity) {
                  updateStockQuantity.add(0);
                  sellQuantity -= individualStockQuantity;
                }
              } else {
                print("Not enough stocks to sell");
                return false;
              }
            }
            // Update users portfolio with the new stock quantity
            for (int i = 0; i < updateStockQuantity.length; i++) {
              await _firestore
                  .collection('Users')
                  .doc(userDoc.id)
                  .collection('portfolio')
                  .doc(stockSnapshot.docs[i].id)
                  .update({
                'quantity': updateStockQuantity[i],
              });
            }
            // Store transaction to stock_transaction_history collection
            double totalPrice =
                double.tryParse(await getCurrentPrice(stockSymbol)) ?? 0.0;
            await _firestore
                .collection('Users')
                .doc(userDoc.id)
                .collection('stock_transaction_history')
                .add({
              'amount': amount,
              'date': Timestamp.now(),
              'price': totalPrice,
              'symbol': stockSymbol,
              'type': false, // true = buy,  false = sell
            });

            return true;
          }
        }
      }
    }
  } catch (e) {
    print('Error: $e');
  }

  return false;
}

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
