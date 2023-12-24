import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/services/stockData_service.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

/// TODO: Wrong password handling, taxes & fees: fees = 1 euro per transaction, taxes = 1000 euro tax free, and when you lose money taxes = amount of money lost + 1000 euro tax free	and when you make money taxes = amount of money made - 1000 euro tax free
/// Function that starts the sell flow.
/// It checks if the user is logged in and if he is, it checks if the password he entered is correct.
/// If the password is correct, it checks if the user has the stock and enough amount to sell.
/// If the user has the stock and enough amount, it adds the amount of money to the user's balance and updates his transaction history.
Future<void> startSellStockFlow(
    BuildContext context, int amount, String stockSymbol) async {
  try {
    final user = _auth.currentUser;
    if (user == null) {
      showToast(message: 'User is not logged in');
      return;
    }

    String? password = await getUserPassword(context);
    if (password == null) {
      showToast(message: 'Password is not provided');
      return;
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } catch (e) {
      showToast(message: 'Password is wrong');
      return;
    }

    final userDoc = (await _firestore
            .collection('Users')
            .where('UID', isEqualTo: user.uid)
            .get())
        .docs
        .first;

    final stockSnapshot = await _firestore
        .collection('Users')
        .doc(userDoc.id)
        .collection('portfolio')
        .where('symbol', isEqualTo: stockSymbol)
        .orderBy('purchaseDate', descending: false)
        .get();

    if (stockSnapshot.docs.isEmpty) {
      showToast(message: 'No stocks found for the symbol');
      return;
    }

    int sellQuantity = amount;
    int totalStocks = 0;
    List<int> updateStockQuantity = [];
    for (final stock in stockSnapshot.docs) {
      totalStocks += int.tryParse(stock['quantity'].toString()) ?? 0;
    }

    if (sellQuantity > totalStocks) {
      showToast(message: 'Not enough stocks to sell');
      return;
    }

    for (final stock in stockSnapshot.docs) {
      // Sell Logic:
      // If the amount of stocks to sell is smaller/same than the total amount of stocks, sell the amount of stocks
      // If the amount of stocks to sell is bigger than the total amount of stocks, error message
      int individualStockQuantity =
          // Get the individual stock quantity
          int.tryParse(stock['quantity'].toString()) ?? 0;
      // Compare the individual stock quantity with the amount of stocks to sell
      // FIFO: First in, first out. If the amount of stocks to sell is smaller/same than the individual stock quantity
      // Than add to list and set the amount of stocks to sell to 0
      if (sellQuantity <= individualStockQuantity) {
        updateStockQuantity.add(individualStockQuantity - sellQuantity);
        sellQuantity = 0;
        // If the amount of stocks to sell is bigger than the individual stock quantity
        // Than add 0 to list and subtract the individual stock quantity from the amount of stocks to sell
        // For the next iteration
      } else if (sellQuantity > individualStockQuantity) {
        updateStockQuantity.add(0);
        sellQuantity -= individualStockQuantity;
      }
    }

    // Update users portfolio with the new stock quantity
    for (int i = 0; i < updateStockQuantity.length; i++) {
      if (updateStockQuantity[i] == 0) {
        // If quantity is 0, delete the stock from the portfolio
        await _firestore
            .collection('Users')
            .doc(userDoc.id)
            .collection('portfolio')
            .doc(stockSnapshot.docs[i].id)
            .delete();
      } else {
        // If quantity is not 0, update the stock quantity
        await _firestore
            .collection('Users')
            .doc(userDoc.id)
            .collection('portfolio')
            .doc(stockSnapshot.docs[i].id)
            .update({
          'quantity': updateStockQuantity[i],
        });
      }
    }

  // Store transaction to stock_transaction_history collection
double singlePrice = double.tryParse(await getCurrentPrice(stockSymbol)) ?? 0.0;
double totalPrice = singlePrice * amount;
double fee = 1.0; // Transaction fee
double totalPriceAfterFee = totalPrice - fee; // Subtract fee from total price

// Retrieve tax_pot from Firestore
double taxPot = (userDoc['tax_pot'] as num).toDouble();

// Calculate new tax_pot
double profit = 0;
for (final stock in stockSnapshot.docs) {
  double purchasePrice = double.tryParse(stock['price'].toString()) ?? 0.0;
  int individualStockQuantity = int.tryParse(stock['quantity'].toString()) ?? 0;
  profit += (singlePrice - purchasePrice) * individualStockQuantity;
}
taxPot += profit;
taxPot -= fee; // subtract fee from tax pot

// Update balance and tax_pot in Firestore
await _firestore.collection('Users').doc(userDoc.id).update({
  'balance': FieldValue.increment(totalPriceAfterFee),
  'tax_pot': taxPot,
});

    await _firestore
        .collection('Users')
        .doc(userDoc.id)
        .collection('stock_transaction_history')
        .add({
      'amount': amount,
      'date': Timestamp.now(),
      'price': totalPrice,
      'symbol': stockSymbol,
      'type': false,
    });

    showToast(message: 'Stocks sold successfully');
  } catch (e) {
    showToast(message: 'Sell failed: ${e.toString()}');
  }
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
