import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/portfolio_model.dart';

class PortfolioService {
  final CollectionReference portfolioCollection =
      FirebaseFirestore.instance.collection('portfolio');

  Future<Portfolio> calculatePortfolioValue(String uid) async {
    var userQuery = await FirebaseFirestore.instance
        .collection('Users')
        .where('UID', isEqualTo: uid)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('No user found with this uid');
    }

    var userDoc = userQuery.docs.first;
    var portfolioSnapshot =
        await userDoc.reference.collection('portfolio').get();

    Map<String, Map<String, double>> stocks = {};

    for (var portfolioDoc in portfolioSnapshot.docs) {
      var portfolio = portfolioDoc.data();
      var symbol = portfolio['symbol'];
      var quantity = (portfolio['quantity'] as num).toDouble();
      var price = (portfolio['price'] as num).toDouble();

      if (!stocks.containsKey(symbol)) {
        stocks[symbol] = {
          'quantity': quantity,
          'totalSpent': quantity * price,
        };
      } else {
        var stock = stocks[symbol];
        if (stock != null) {
          stock['quantity'] = (stock['quantity'] ?? 0.0) + quantity;
          stock['totalSpent'] = (stock['totalSpent'] ?? 0.0) + quantity * price;
        }
      }
    }

    double totalCurrentValue = 0.0;
    double totalProfitOrLoss = 0.0;

    for (var symbol in stocks.keys) {
      var stock = stocks[symbol];
      var quantity = stock?['quantity'] ?? 0.0;
      var totalSpent = stock?['totalSpent'] ?? 0.0;
      var currentValue = quantity * (await getCurrentPrice(symbol) ?? 0.0);
      var profitOrLoss = currentValue - totalSpent;

      totalCurrentValue += currentValue;
      totalProfitOrLoss += profitOrLoss;
    }

    double percentageGainOrLoss = totalCurrentValue != 0
        ? totalProfitOrLoss / totalCurrentValue * 100
        : 0.0;
    return Portfolio(
      portfolioValue: totalCurrentValue,
      profitOrLoss: totalProfitOrLoss,
      percentageGainOrLoss: percentageGainOrLoss,
    );
  }

  Future<double?> getCurrentPrice(String symbol) async {
    final response = await http.get(Uri.parse(
        'https://financialmodelingprep.com/api/v3/profile/$symbol?apikey=KKCRslaWI36ENKmv2yKfduM44Z5EDm0X'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data[0]['price'];
    } else {
      throw Exception('Failed to load stock price');
    }
  }

  Stream<List<Map<String, dynamic>>> getIndividualInvestmentsStream(
      {required String uid}) {
    return FirebaseFirestore.instance
        .collection('Users')
        .where('UID', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        throw Exception('No user found with this uid');
      }

      var userDoc = snapshot.docs.first;
      var portfolioSnapshot =
          await userDoc.reference.collection('portfolio').get();

      Map<String, Map<String, dynamic>> investments = {};

      for (var portfolioDoc in portfolioSnapshot.docs) {
        var portfolio = portfolioDoc.data();
        var symbol = portfolio['symbol'];
        var quantity = (portfolio['quantity'] as num).toDouble();
        var price = (portfolio['price'] as num).toDouble();
        var purchaseDate = (portfolio['purchaseDate'] as Timestamp).toDate();
        var totalValue = quantity * (await getCurrentPrice(symbol) ?? 0.0);
        var profitOrLoss = totalValue - quantity * price;
        var percentageGainOrLoss = profitOrLoss / totalValue * 100;

        if (investments.containsKey(symbol)) {
          investments[symbol]?['quantity'] += quantity;
          investments[symbol]?['totalValue'] += totalValue;
          investments[symbol]?['profitOrLoss'] += profitOrLoss;
        } else {
          investments[symbol] = {
            'name': portfolio['name'],
            'symbol': symbol,
            'quantity': quantity,
            'price': price,
            'purchaseDate': purchaseDate,
            'totalValue': totalValue,
            'profitOrLoss': profitOrLoss,
            'percentageGainOrLoss': percentageGainOrLoss,
          };
        }
      }

      return investments.values.toList();
    });
  }

  Future<List<Map<String, dynamic>>> getWatchlist(String uid) async {
    var userQuery = await FirebaseFirestore.instance
        .collection('Users')
        .where('UID', isEqualTo: uid)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('No user found with this uid');
    }

    var userDoc = userQuery.docs.first;
    var watchlistSnapshot =
        await userDoc.reference.collection('watchlist').get();

    List<Map<String, dynamic>> watchlist = [];

    for (var watchlistDoc in watchlistSnapshot.docs) {
      var watchlistItem = watchlistDoc.data();
      var name = watchlistItem['name'];
      var symbol = watchlistItem['symbol'];

      watchlist.add({
        'name': name,
        'symbol': symbol,
      });
    }

    return watchlist;
  }

  Future<void> addToWatchlist(String uid, String name, String symbol) async {
    var userQuery = await FirebaseFirestore.instance
        .collection('Users')
        .where('UID', isEqualTo: uid)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('No user found with this uid');
    }

    var userDoc = userQuery.docs.first;
    var watchlistSnapshot =
        await userDoc.reference.collection('watchlist').get();

    for (var watchlistDoc in watchlistSnapshot.docs) {
      var watchlistItem = watchlistDoc.data();
      var watchlistSymbol = watchlistItem['symbol'];

      if (watchlistSymbol == symbol) {
        throw Exception('Stock already in watchlist');
      }
    }

    await userDoc.reference.collection('watchlist').add({
      'name': name,
      'symbol': symbol,
    });
  }

  Future<void> removeFromWatchlist(String uid, String symbol) async {
    var userQuery = await FirebaseFirestore.instance
        .collection('Users')
        .where('UID', isEqualTo: uid)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('No user found with this uid');
    }

    var userDoc = userQuery.docs.first;
    var watchlistSnapshot =
        await userDoc.reference.collection('watchlist').get();

    for (var watchlistDoc in watchlistSnapshot.docs) {
      var watchlistItem = watchlistDoc.data();
      var watchlistSymbol = watchlistItem['symbol'];

      if (watchlistSymbol == symbol) {
        await watchlistDoc.reference.delete();
        return;
      }
    }

    throw Exception('Stock not found in watchlist');
  }

  Future<bool> checkIfInWatchlist(String uid, String symbol) async {
    var userQuery = await FirebaseFirestore.instance
        .collection('Users')
        .where('UID', isEqualTo: uid)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('No user found with this uid');
    }

    var userDoc = userQuery.docs.first;
    var watchlistSnapshot =
        await userDoc.reference.collection('watchlist').get();

    for (var watchlistDoc in watchlistSnapshot.docs) {
      var watchlistItem = watchlistDoc.data();
      var watchlistSymbol = watchlistItem['symbol'];

      if (watchlistSymbol == symbol) {
        return true;
      }
    }

    return false;
  }
}
