/// Portfolio model class
/// Displaying on the [PortfolioOverview]
/// [portfolioValue] is the total value of all investments
/// [profitOrLoss] is the total profit or loss of all investments
/// [percentageGainOrLoss] is the total percentage gain or loss of all investments
class Portfolio {
  final double portfolioValue;
  final double profitOrLoss;
  final double percentageGainOrLoss;

  Portfolio({
    required this.portfolioValue,
    required this.profitOrLoss,
    required this.percentageGainOrLoss,
  });
}
