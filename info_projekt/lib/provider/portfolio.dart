import 'package:flutter/foundation.dart';
import 'package:info_projekt/models/portfolio_model.dart';

class PortfolioValueNotifier extends ChangeNotifier {
  Portfolio _portfolio =
      Portfolio(portfolioValue: 0, profitOrLoss: 0, percentageGainOrLoss: 0);

  Portfolio get portfolio => _portfolio;

  void setPortfolio(Portfolio newPortfolio) {
    _portfolio = newPortfolio;
    notifyListeners();
  }
}
