import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/services/stockData_service.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

/// TODO: Pop up not enough money
/// Function that starts the buy flow.
/// It checks if the user is logged in
/// If the user has enough money, it subtracts the amount of money from the user's balance and adds the stock to his transaction history.
Future<void> startBuyStockFlow(int amount, String stockSymbol) async {
  bool overrideMarketOpen = false; // Override market open for testing
  try {
    // Check if the market is open
    if (!await isMarketOpen() && !overrideMarketOpen) {
      showToast(
          message:
              "The stock market is currently closed. Please try again during opening hours.");
      return;
    }

    final user = _auth.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('UID', isEqualTo: user.uid)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final userDoc = querySnapshot.docs.first;
        String? singlePriceString = await getCurrentPrice(stockSymbol);
        double singlePrice = double.tryParse(singlePriceString) ?? 0.0;
        double fee = 1.0; // Transaction fee
        double totalCost =
            singlePrice * amount + fee; // Total cost including fee

        if (totalCost > userDoc['balance']) {
          showToast(message: "Not enough money");
          return;
        }

        // Retrieve tax_pot from Firestore
        double taxPot = (userDoc['tax_pot'] as num).toDouble();

        // Subtract fee from taxPot
        taxPot -= fee;

        await _firestore.collection('Users').doc(userDoc.id).update({
          'balance': FieldValue.increment(-totalCost),
          // update tax_pot: subtract the fee from the tax pot
          'tax_pot': taxPot,
        });

        await _firestore
            .collection('Users')
            .doc(userDoc.id)
            .collection('stock_transaction_history')
            .add({
          'amount': amount,
          'date': Timestamp.now(),
          'price': singlePrice, // Updated to reflect total price after fee
          'symbol': stockSymbol,
          'type': true, // true = buy,  false = sell
        });

        String? companyName = await getCompanyName(stockSymbol);

        await _firestore
            .collection('Users')
            .doc(userDoc.id)
            .collection('portfolio')
            .add({
          'name': companyName,
          'price': singlePrice,
          'purchaseDate': Timestamp.now(),
          'quantity': amount,
          'symbol': stockSymbol,
        });

        showToast(message: "Transaction successful");
      } else {
        showToast(message: "User not found");
      }
    }
  } on Exception catch (e) {
    showToast(message: "Buy failed: $e");
  }
}
