import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/services/stockData_service.dart';
import 'package:info_projekt/globals.dart';
import 'package:intl/intl.dart';

final _auth = FirebaseAuth.instance;
final _firestore = FirebaseFirestore.instance;

/// Function that starts the sell flow, if the market is open.
/// It checks if the user has the stock and enough amount to sell in FIFO order.
/// If the user has the stock and enough amount, it adds the amount of money to the user's balance and updates his transaction history.
/// Taxes are calculated and subtracted from the profit, if the user's tax pot is not negative.
/// Transaction fees are subtracted from the profit.
Future<bool> startSellStockFlow(int amount, String stockSymbol) async {
  try {
    // Check if the market is open
    if (!await isMarketOpen() && !overrideMarketOpen) {
      showToast(
          message:
              "The stock market is currently closed. Please try again during opening hours.");
      return false;
    }

    final user = _auth.currentUser;
    if (user != null) {
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
        return false;
      }

      int sellQuantity = amount;
      int totalStocks = 0;
      double totalProfit = 0;
      double revenue = 0;
      double totalBuyPrice = 0;
      double singleSellPrice =
          double.tryParse(await getCurrentPrice(stockSymbol)) ?? 0.0;
      List<int> updateStockQuantity = [];
      for (final stock in stockSnapshot.docs) {
        totalStocks += int.tryParse(stock['quantity'].toString()) ?? 0;
      }

      if (sellQuantity > totalStocks) {
        showToast(message: 'Not enough stocks to sell');
        return false;
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

          // Calculate profit & revenue & totalBuyPrice
          revenue += singleSellPrice * sellQuantity;
          totalBuyPrice += (double.tryParse(stock['price'].toString()) ?? 0.0) *
              sellQuantity;
          totalProfit += (singleSellPrice -
                  (double.tryParse(stock['price'].toString()) ?? 0.0)) *
              sellQuantity;

          sellQuantity = 0;
          // If the amount of stocks to sell is bigger than the individual stock quantity
          // Than add 0 to list and subtract the individual stock quantity from the amount of stocks to sell
          // For the next iteration
        } else if (sellQuantity > individualStockQuantity) {
          updateStockQuantity.add(0);
          sellQuantity -= individualStockQuantity;

          // Calculate profit & revenue & totalBuyPrice
          revenue += singleSellPrice * individualStockQuantity;
          totalBuyPrice += (double.tryParse(stock['price'].toString()) ?? 0.0) *
              individualStockQuantity;
          totalProfit += (singleSellPrice -
                  (double.tryParse(stock['price'].toString()) ?? 0.0)) *
              individualStockQuantity;
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

      // Get the current tax pot
      double oldTaxPot = double.tryParse(userDoc['tax_pot'].toString()) ?? 0.0;

      double taxedProfit = 0;
      double addToBalance = 0;
      double newTaxPot = 0;
      double fee = 1;
      totalProfit -= fee;

      // Calculate taxed profit
      switch (totalProfit) {
        case < 0:
          newTaxPot = oldTaxPot + totalProfit;
          addToBalance += revenue - fee;
          break;

        case > 0:
          if (oldTaxPot < 0) {
            newTaxPot = oldTaxPot + totalProfit;
            if (newTaxPot > 0) {
              taxedProfit = calculateTaxedProfit(newTaxPot);
              addToBalance += taxedProfit;
              newTaxPot = 0;
              addToBalance += (newTaxPot -
                  oldTaxPot); // Nicht zu versteuernder Gewinn bis Taxpot 0 ist
              addToBalance += totalBuyPrice;
            } else {
              addToBalance +=
                  revenue; // Nicht zu versteuernder Gewinn, wenn Taxpot negativ ist
            }
          } else {
            // Taxpot = 0, da taxpot nie positiv ist
            taxedProfit = calculateTaxedProfit(totalProfit);
            addToBalance += taxedProfit;
            addToBalance += totalBuyPrice;
            newTaxPot = 0;
          }
          break;

        default:
          print("Default");
          break;
      }

      // Update balance and tax_pot in Firestore
      double newBalance = double.tryParse(userDoc['balance'].toString()) ?? 0.0;
      newBalance += addToBalance;

      newBalance = double.parse(newBalance.toStringAsFixed(2));
      newTaxPot = double.parse(newTaxPot.toStringAsFixed(2));
      await _firestore.collection('Users').doc(userDoc.id).update({
        'balance': newBalance,
        'tax_pot': newTaxPot,
      });

      // Store transaction to stock_transaction_history collection
      await _firestore
          .collection('Users')
          .doc(userDoc.id)
          .collection('stock_transaction_history')
          .add({
        'amount': amount,
        'date': Timestamp.now(),
        'price': revenue,
        'symbol': stockSymbol,
        'type': false,
      });

      // Send Mail to user TODO: Rewrite this
      final DateTime now = DateTime.now();
      Random random = Random();
      int receiptID = 10000 + random.nextInt(90000);
      String companyName = await getCompanyName(stockSymbol);
      double taxZwischen = (revenue - addToBalance - fee);
      double tax = taxZwischen < 0 ? 0 : taxZwischen;
      double kapiTax = ((tax / 26.3750) * 100) * 0.25;
      double soliTax = ((tax / 26.3750) * 100) * 0.01375;
      await _firestore.collection("mail").add({
        'to': user.email,
        'template': {
          'name': "sell",
          'data': {
            'purchase_date': DateFormat('dd.MM.yyyy HH:mm').format(now),
            'date': DateFormat('HH:mm dd.MM.yyyy').format(now),
            'receipt_id': receiptID,
            'description': "$companyName ($stockSymbol)",
            'amount': amount,
            'singlePrice': NumberFormat.currency(
              locale: 'en_US',
              symbol: '\$',
            ).format(singleSellPrice),
            'fee': NumberFormat.currency(
              locale: 'en_US',
              symbol: '\$',
            ).format(fee),
            'kapiTax': NumberFormat.currency(
              locale: 'en_US',
              symbol: '\$',
            ).format(kapiTax),
            'soliTax': NumberFormat.currency(
              locale: 'en_US',
              symbol: '\$',
            ).format(soliTax),
            'total': NumberFormat.currency(
              locale: 'en_US',
              symbol: '\$',
            ).format(addToBalance),
          },
        },
      });

      showToast(message: 'Stocks sold successfully');
      return true;
    }
  } catch (e) {
    print(e); // TODO: DEBUG Remove this
    showToast(message: 'Sell failed: ${e.toString()}');
  }

  return false;
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

/// Function that calculates the taxed profit.
/// Taxes in Germany are 25% Kapitalertragsteuer and 5.5% Solidaritätszuschlag.
double calculateTaxedProfit(double profit) {
  double taxedProfit = 0;

  double kapitalertragssteuer = profit * 0.25; // Kapitalertragsteuer
  double mitSoli = kapitalertragssteuer * 0.055; // Solidaritätzuschlag

  taxedProfit = profit - kapitalertragssteuer - mitSoli;

  return taxedProfit;
}
