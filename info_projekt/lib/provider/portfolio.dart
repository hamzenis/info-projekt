import 'package:flutter/foundation.dart';
import 'package:info_projekt/models/portfolio_model.dart';
import 'package:info_projekt/services/portfolio_service.dart';

class PortfolioValueNotifier extends ChangeNotifier {
  Portfolio _portfolio =
      Portfolio(portfolioValue: 0, profitOrLoss: 0, percentageGainOrLoss: 0);
  final String uid;
  final PortfolioService _portfolioService = PortfolioService();

  PortfolioValueNotifier(this.uid) {
    fetchPortfolioValue();
  }

  Portfolio get portfolio => _portfolio;

  Future<void> fetchPortfolioValue() async {
    try {
      Portfolio newPortfolio =
          await _portfolioService.calculatePortfolioValue(uid);
      setPortfolio(newPortfolio);
    } catch (e) {
      // handle error
    }
  }

  void setPortfolio(Portfolio newPortfolio) {
    _portfolio = newPortfolio;
    notifyListeners();
  }

  void reset() {
    _portfolio = Portfolio(
        portfolioValue: 0.0, profitOrLoss: 0.0, percentageGainOrLoss: 0.0);
    notifyListeners();
  }
}
