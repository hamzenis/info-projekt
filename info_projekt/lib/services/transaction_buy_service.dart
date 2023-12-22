import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/services/stockData_service.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

/// TODO: Check total price calculation & wrong password handling, pop up not enough money
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
          showToast(message: "Incorrect password");
          return;
        }

        final querySnapshot = await _firestore
            .collection('Users')
            .where('UID', isEqualTo: user.uid)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          final userDoc = querySnapshot.docs.first;
          String? singlePriceString = await getCurrentPrice(stockSymbol);
          double singlePrice = double.tryParse(singlePriceString) ?? 0.0;
          double totalPrice = singlePrice * amount;
          double fee = 1.0; // Transaction fee
          totalPrice += fee; // Add fee to total price

          if (totalPrice > userDoc['balance'] && !kDebugMode) {
            showToast(message: "Not enough money");
            return;
          }

          await _firestore.collection('Users').doc(userDoc.id).update({
            'balance': FieldValue.increment(-totalPrice),
          });

          await _firestore
              .collection('Users')
              .doc(userDoc.id)
              .collection('stock_transaction_history')
              .add({
            'amount': amount,
            'date': Timestamp.now(),
            'price': totalPrice, // Updated to reflect total price after fee
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
            'price': totalPrice, // Updated to reflect total price after fee
            'purchaseDate': Timestamp.now(),
            'quantity': amount,
            'symbol': stockSymbol,
          });

          showToast(message: "Transaction successful");

        } else {
          showToast(message: "User not found");
        }
      }
    }
  } on Exception catch (e) {
    showToast(message: "Buy failed: $e");
  }
}

/// Function that alerts the user via a popup that the password he entered is incorrect.
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