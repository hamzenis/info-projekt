import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/portfolio_model.dart';

/// The brain of the portfolio.
/// This class is responsible for calculating the portfolio value and the profit/loss of the user.
/// It also provides the stream for the individual investments of the user.
/// It also provides the methods for the watchlist.
class PortfolioService {
  final CollectionReference portfolioCollection =
      FirebaseFirestore.instance.collection('portfolio');

  /// Calculates the portfolio value and the profit/loss of the user.
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

    Map<String, Map<String, dynamic>> investments = {};

    for (var portfolioDoc in portfolioSnapshot.docs) {
      var portfolio = portfolioDoc.data();
      var symbol = portfolio['symbol'];
      var quantity = (portfolio['quantity'] as num).toDouble();
      var price = (portfolio['price'] as num).toDouble();
      var purchaseDate = (portfolio['purchaseDate'] as Timestamp).toDate();
      var totalValue = quantity * (await getCurrentPrice(symbol) ?? 0.0);
      var profitOrLoss = totalValue - quantity * price;
      var percentageGainOrLoss = totalValue * 100 / (price * quantity) - 100;

      if (investments.containsKey(symbol)) {
        investments[symbol]?['quantity'] += quantity;
        investments[symbol]?['totalValue'] += totalValue;
        investments[symbol]?['profitOrLoss'] += profitOrLoss;
        investments[symbol]?['percentageGainOrLoss'] += percentageGainOrLoss;
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

    double totalCurrentValue = 0.0;
    double totalCostBasis = 0.0;
    double totalProfitOrLoss = 0.0;
    double totalPercentageGainOrLoss = 0.0;

    for (var portfolio in portfolioSnapshot.docs) {
      var investment = portfolio.data();
      var costBasis = investment['quantity'] * investment['price'];

      totalCostBasis += costBasis;
    }

    for (var investment in investments.values) {
      totalCurrentValue += investment['totalValue'];
      totalProfitOrLoss += investment['profitOrLoss'];
    }

    if (totalCostBasis != 0) {
      totalPercentageGainOrLoss =
          totalCurrentValue * 100 / totalCostBasis - 100;
    } else {
      totalPercentageGainOrLoss = 0.0;
    }
    return Portfolio(
      portfolioValue: totalCurrentValue,
      profitOrLoss: totalProfitOrLoss,
      percentageGainOrLoss: totalPercentageGainOrLoss,
    );
  }

  /// Gets the current price of a stock.
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

  /// Gets the stream of the individual investments of the user.
  /// The stream is updated whenever the user buys or sells a stock.
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

        if (investments.containsKey(symbol)) {
          investments[symbol]?['quantity'] += quantity;
          investments[symbol]?['totalValue'] += totalValue;
          investments[symbol]?['profitOrLoss'] += profitOrLoss;
          investments[symbol]?['purchases']
              .add({'quantity': quantity, 'price': price});
        } else {
          investments[symbol] = {
            'name': portfolio['name'],
            'symbol': symbol,
            'quantity': quantity,
            'price': price,
            'purchaseDate': purchaseDate,
            'totalValue': totalValue,
            'profitOrLoss': profitOrLoss,
            'purchases': [
              {'quantity': quantity, 'price': price}
            ],
          };
        }
      }

      for (var symbol in investments.keys) {
        var totalValue = investments[symbol]?['totalValue'] as double;
        var totalCost = 0.0;
        for (var purchase in investments[symbol]?['purchases']) {
          totalCost += purchase['quantity'] * purchase['price'];
        }

        investments[symbol]?['percentageGainOrLoss'] =
            totalValue * 100 / totalCost - 100;
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
