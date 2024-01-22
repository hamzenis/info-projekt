import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:info_projekt/pages/portfolio_overview.dart';
import 'package:info_projekt/provider/portfolio.dart';
import 'package:info_projekt/services/firebase_auth_services.dart';
import 'package:info_projekt/services/portfolio_service.dart';
import 'package:info_projekt/services/stockData_service.dart';
import 'package:info_projekt/services/transaction_sell_service.dart';
import 'package:info_projekt/views/charts_view.dart';
import 'package:info_projekt/widgets/password_input_widget.dart';
import 'package:provider/provider.dart';

/// This Class is responsible for displaying the investments of the user.
class InvestmentPage extends StatefulWidget {
  final ValueNotifier<List<Map<String, dynamic>>> investments;
  final String uid;
  final ValueNotifier<bool> refreshNotifier;
  final PortfolioOverview portfolioOverview;

  InvestmentPage(this.investments, this.uid, this.refreshNotifier, {Key? key})
      : portfolioOverview = PortfolioOverview(refreshNotifier, uid),
        super(key: key);

  @override
  InvestmentPageState createState() => InvestmentPageState();
}

class InvestmentPageState extends State<InvestmentPage> {
  bool showPercentage = false;
  final portfolioValueNotifierKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchInvestments();
    widget.refreshNotifier.addListener(_fetchInvestments);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_fetchInvestments);
    super.dispose();
  }

  void _fetchInvestments() {
    widget.investments.value = [];
    PortfolioService()
        .getIndividualInvestmentsStream(uid: widget.uid)
        .listen((investments) {
      setState(() {
        widget.investments.value = investments;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)!.isCurrent) {
      _fetchInvestments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioValueNotifier =
        Provider.of<PortfolioValueNotifier>(context, listen: false);
    return widget.investments.value.isEmpty
        ? const Text(
            'Here appears your investments',
            style: TextStyle(color: Colors.grey),
          )
        : ValueListenableBuilder(
            valueListenable: widget.investments,
            builder: (context, value, child) {
              return ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  var investment = value.firstWhere(
                    (inv) => inv['symbol'] == value[index]['symbol'],
                    orElse: () => <String, dynamic>{},
                  );
                  bool isInvestmentProfit = investment['profitOrLoss'] > 0;
                  bool isZero = investment['profitOrLoss'] == 0.00;

                  return GestureDetector(
                    onTap: () async {
                      int? amount = await _showAmountDialog(context);
                      if (amount != null) {
                        // ignore: use_build_context_synchronously
                        bool success = await _sellStock(context, amount,
                            investment, portfolioValueNotifier);
                        if (success) {
                          // ignore: use_build_context_synchronously
                          await _updateInvestment(context, amount, investment,
                              portfolioValueNotifier);
                        }
                      }
                    },
                    child: ListTile(
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(investment['name']),
                          ),
                          Text(
                            '\$${investment['totalValue'].toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isInvestmentProfit
                                  ? Colors.green
                                  : (isZero ? Colors.grey : Colors.red),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quantity: ${investment['quantity'].toDouble().toInt()}',
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showPercentage = !showPercentage;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isInvestmentProfit
                                          ? Icons.keyboard_arrow_up
                                          : (isZero
                                              ? Icons.keyboard_arrow_right
                                              : Icons.keyboard_arrow_down),
                                      color: isInvestmentProfit
                                          ? Colors.green
                                          : (isZero ? Colors.grey : Colors.red),
                                    ),
                                    Text(
                                      showPercentage
                                          ? '${investment['percentageGainOrLoss'].toStringAsFixed(2)}%'
                                          : '\$${investment['profitOrLoss'].toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isInvestmentProfit
                                            ? Colors.green
                                            : (isZero
                                                ? Colors.grey
                                                : Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
  }

  /// This method updates the investment after the user sold a stock.
  Future<void> _updateInvestment(
      BuildContext context,
      int amount,
      Map<String, dynamic> investment,
      PortfolioValueNotifier portfolioValueNotifier) async {
    // Find the investment that matches the sold stock
    var soldInvestment = widget.investments.value.firstWhere(
      (inv) => inv['symbol'] == investment['symbol'],
      orElse: () => <String, dynamic>{},
    );

    // If the investment was found, decrease its quantity
    if (soldInvestment.isNotEmpty) {
      soldInvestment['quantity'] -= amount;

      // Get the current price of the stock
      double currentPrice =
          double.parse(await getCurrentPrice(soldInvestment['symbol']));

      // Calculate the new total value
      soldInvestment['totalValue'] = currentPrice * soldInvestment['quantity'];

      // Calculate the total initial investment (quantity * purchase price)
      double totalInitialInvestment =
          soldInvestment['quantity'] * soldInvestment['price'];

      // Calculate the new profit/loss and percentage gain/loss
      soldInvestment['profitOrLoss'] =
          soldInvestment['totalValue'] - totalInitialInvestment;
      soldInvestment['percentageGainOrLoss'] =
          (soldInvestment['profitOrLoss'] / totalInitialInvestment) * 100;

      // If the quantity is 0, remove the investment from the list
      if (soldInvestment['quantity'] == 0) {
        widget.investments.value = List.from(widget.investments.value)
          ..remove(soldInvestment);
      } else {
        // Check if soldInvestment is in the list before trying to update it
        int index = widget.investments.value.indexOf(soldInvestment);
        if (index != -1) {
          setState(() {
            widget.investments.value = List.from(widget.investments.value)
              ..[index] = soldInvestment;
          });
        }
      }

      // Update the PortfolioValueNotifier with the new portfolio
      if (mounted) {
        portfolioValueNotifier.fetchPortfolioValue();
      }
    }
  }

  Future<int?> _showAmountDialog(BuildContext context) async {
    return await showDialog<int>(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('How many shares do you want to sell?'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(
                RegExp(r'[0-9]'),
              ),
            ],
            decoration: const InputDecoration(
              hintText: 'Amount',
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  child: const Icon(Icons.info),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Stock Information'),
                          content: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text(
                                  'Name: ${widget.investments.value[0]['name']},\n'
                                  'Symbol: ${widget.investments.value[0]['symbol']},\n'
                                  'Quantity: ${widget.investments.value[0]['quantity'].toDouble().toInt()},\n'
                                  'Total Value: \$${widget.investments.value[0]['totalValue'].toStringAsFixed(2)},\n'
                                  'Profit/Loss: \$${widget.investments.value[0]['profitOrLoss'].toStringAsFixed(2)},\n'
                                  'Percentage Gain/Loss: ${widget.investments.value[0]['percentageGainOrLoss'].toStringAsFixed(2)}%',
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: const Text('OK'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                TextButton(
                  child: const Icon(Icons.show_chart),
                  onPressed: () {
                    MaterialPageRoute route = MaterialPageRoute(
                      builder: (context) => ChartStock(
                        title: widget.investments.value[0]['symbol'],
                      ),
                    );
                    Navigator.push(context, route);
                  },
                ),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Sell'),
                  onPressed: () {
                    int amount = int.tryParse(controller.text) ?? 0;
                    Navigator.of(context).pop(amount);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<bool> _sellStock(
      BuildContext context,
      int amount,
      Map<String, dynamic> investment,
      PortfolioValueNotifier portfolioValueNotifier) async {
    String? password = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return PasswordDialog();
      },
    );
    FirebaseAuthService auth = FirebaseAuthService();
    bool correctPassword = await auth.reauthenticateUser(password);
    bool success = false;

    if (correctPassword) {
      try {
        success = await startSellStockFlow(amount, investment['symbol']);
      } catch (e) {
        //TODO: DEBUG Line
      }
    }

    // Refresh page if the stock was successfully sold
    if (success && mounted) {
      portfolioValueNotifier.fetchPortfolioValue();
    }

    return success;
  }
}
