import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/services/stockData_service.dart';
import 'package:info_projekt/globals.dart';
import 'package:intl/intl.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

/// Function that starts the buy flow, if the market is open.
/// If the user has enough money, it subtracts the amount of money from the user's balance
/// and adds the stock to his transaction history.
/// Transaction fees are added to the tax pot and subtracted from the user's balance.
Future<void> startBuyStockFlow(int amount, String stockSymbol) async {
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

        // Add stock to portfolio
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

        /** add a new mail document */
        final DateTime now = DateTime.now();
        Random random = Random();
        int random5DigitNumber = 10000 + random.nextInt(90000);
        await _firestore.collection("mail").add({
          'to': user.email,
          'template': {
            'name': "buy",
            'data': {
              'purchase_date': DateFormat('hh:mm dd-MM-yyyy').format(now),
              'date': DateFormat('hh:mm dd-MM-yyyy').format(now),
              'receipt_id': random5DigitNumber,
              'description': "Beispiel Desc",
              'amount': "4",
              'total': "€ 123.45",
            },
          },
        });

        // Show toast
        showToast(message: "Transaction successful");
      } else {
        showToast(message: "User not found");
      }
    }
  } on Exception catch (e) {
    showToast(message: "Buy failed: $e");
  }
}

/// Function to assemble the email body for the transaction confirmation email.
String assembleEmailBody(String stockSymbol, int amount, double singlePrice) {
  String emailBody =
      "You have successfully bought $amount shares of $stockSymbol for $singlePrice € each.";
  return emailBody;
}
