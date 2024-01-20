import 'package:flutter/material.dart';
import 'package:info_projekt/models/portfolio_model.dart';
import 'package:info_projekt/provider/portfolio.dart';
import 'package:info_projekt/services/portfolio_service.dart';
import 'package:provider/provider.dart';

class PortfolioOverview extends StatefulWidget {
  final String uid;

  PortfolioOverview({Key? key, required this.uid}) : super(key: key);

  @override
  PortfolioOverviewState createState() => PortfolioOverviewState();
}

class PortfolioOverviewState extends State<PortfolioOverview>
    with SingleTickerProviderStateMixin {
  Portfolio? portfolio;
  ValueNotifier<bool> showPercentage = ValueNotifier<bool>(false);
  VoidCallback? onTogglePercentage;
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    fetchPortfolioData();
    onTogglePercentage = () {
      showPercentage.value = !showPercentage.value;
    };
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> fetchPortfolioData() async {
    PortfolioService portfolioService = PortfolioService();
    portfolio = await portfolioService.calculatePortfolioValue(widget.uid);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioValueNotifier>(
      builder: (context, portfolioValueNotifier, child) {
        Portfolio portfolio = portfolioValueNotifier.portfolio;
        if (portfolio == null) {
          return CircularProgressIndicator();
        } else {
          return Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  buildPortfolioHeader(context, portfolio),
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget buildPortfolioHeader(BuildContext context, Portfolio portfolio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: buildPortfolioValueAndChange(portfolio)),
        buildRefreshButton(context),
      ],
    );
  }

  Widget buildPortfolioValueAndChange(Portfolio portfolio) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Column(
        children: [
          Text(
            '\$${portfolio?.portfolioValue.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          buildProfitOrLossToggle(portfolio),
        ],
      ),
    );
  }

  Widget buildProfitOrLossToggle(Portfolio portfolio) {
    return GestureDetector(
      onTap: onTogglePercentage,
      child: ValueListenableBuilder<bool>(
        valueListenable: showPercentage,
        builder: (context, value, child) {
          String displayValue =
              '\$${portfolio?.profitOrLoss.toStringAsFixed(2)}';
          if (value) {
            displayValue =
                '${portfolio?.percentageGainOrLoss.toStringAsFixed(2)}%';
          }
          return Text(
            displayValue,
            style: TextStyle(
              fontSize: 20,
              color: portfolio!.profitOrLoss > 0
                  ? Colors.green
                  : (portfolio?.profitOrLoss == 0.00
                      ? Colors.grey
                      : Colors.red),
            ),
          );
        },
      ),
    );
  }

  Widget buildRefreshButton(BuildContext context) {
    return IconButton(
      icon: RotationTransition(
        turns: _controller!,
        child: Icon(Icons.refresh),
      ),
      onPressed: () {
        _controller?.repeat();
        Provider.of<PortfolioValueNotifier>(context, listen: false)
            .fetchPortfolioValue()
            .then((_) {
          _controller?.stop();
        });
      },
    );
  }
}
