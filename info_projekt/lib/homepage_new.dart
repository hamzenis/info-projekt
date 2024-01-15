import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:info_projekt/pages/profile_page.dart';
import 'package:info_projekt/provider/portfolio.dart';
import 'package:info_projekt/services/firebase_auth_services.dart';
import 'package:info_projekt/services/transaction_sell_service.dart';
import 'package:info_projekt/views/charts_view.dart';
import 'package:info_projekt/views/charts_view2.dart';
import 'package:info_projekt/views/wallet_screen.dart';
import 'package:info_projekt/widgets/password_input_widget.dart';
import 'package:info_projekt/widgets/watchlist_button.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'models/portfolio_model.dart';
import 'views/search_view.dart';
import 'views/newspage.dart';
import 'services/portfolio_service.dart';

class HomePageNew extends StatefulWidget {
  @override
  _HomePageNewState createState() => _HomePageNewState();
}

class _HomePageNewState extends State<HomePageNew> {
  static const _actionTitles = ['Search', 'News', 'Profile', 'Wallet'];
  final PortfolioService portfolioService = PortfolioService();

  void _showAction(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(_actionTitles[index]),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TradeMate'),
      ),
      body: PortfolioPage(),
      floatingActionButton: ExpandableFab(
        distance: 100,
        children: [
          ActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SearchPage(
                          title: 'Search Page',
                        )),
              );
              setState(() {});
            },
            icon: const Icon(Icons.search),
          ),
          ActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewsPage()),
              );
              setState(() {});
            },
            icon: const Icon(Icons.newspaper),
          ),
          ActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(
                        // title: "User Profile",
                        )),
              );
              setState(() {});
            },
            icon: const Icon(Icons.person),
          ),
          ActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WalletScreen()),
              );
              setState(() {});
            },
            icon: const Icon(Icons.wallet),
          ),
        ],
      ),
    );
  }
}

@immutable
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            child: const Icon(Icons.menu),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
  });

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.secondary,
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: theme.colorScheme.onSecondary,
      ),
    );
  }
}

class PortfolioPage extends StatefulWidget {
  @override
  _PortfolioPageState createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final PortfolioService portfolioService = PortfolioService();
  ValueNotifier<bool> showPercentage = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
        portfolioService.calculatePortfolioValue(user.uid).then((portfolio) {
          var portfolioValueNotifier =
              Provider.of<PortfolioValueNotifier>(context, listen: false);
          portfolioValueNotifier.setPortfolio(portfolio);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return user == null
        ? Center(child: Text('Please log in'))
        : FutureBuilder<Portfolio>(
            future: portfolioService.calculatePortfolioValue(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                WidgetsBinding.instance!.addPostFrameCallback((_) {
                  var portfolioValueNotifier =
                      Provider.of<PortfolioValueNotifier>(context,
                          listen: false);
                  portfolioValueNotifier.setPortfolio(snapshot.data!);
                });

                return Consumer<PortfolioValueNotifier>(
                  builder: (context, portfolioValueNotifier, child) {
                    return PortfolioOverview(
                      portfolioValue:
                          portfolioValueNotifier.portfolio.portfolioValue,
                      profitOrLoss:
                          portfolioValueNotifier.portfolio.profitOrLoss,
                      percentageGainOrLoss:
                          portfolioValueNotifier.portfolio.percentageGainOrLoss,
                      showPercentage: showPercentage,
                      onTogglePercentage: () {
                        showPercentage.value = !showPercentage.value;
                      },
                      individualInvestments:
                          FutureBuilder<List<Map<String, dynamic>>>(
                        future:
                            portfolioService.getIndividualInvestments(user.uid),
                        builder: (context, investmentSnapshot) {
                          if (investmentSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          } else if (investmentSnapshot.hasError) {
                            return Center(
                                child:
                                    Text('Error: ${investmentSnapshot.error}'));
                          } else {
                            return InvestmentList(investmentSnapshot.data!);
                          }
                        },
                      ),
                    );
                  },
                );
              }
            },
          );
  }

  String valueToString(bool isProfit, double value) {
    return showPercentage.value
        ? '${value.toStringAsFixed(2)}%'
        : '\$${value.toStringAsFixed(2)}';
  }
}

class PortfolioOverview extends StatefulWidget {
  final double portfolioValue;
  final double profitOrLoss;
  final double percentageGainOrLoss;
  final ValueNotifier<bool> showPercentage;
  final VoidCallback onTogglePercentage;
  final Widget individualInvestments;

  PortfolioOverview({
    required this.portfolioValue,
    required this.profitOrLoss,
    required this.percentageGainOrLoss,
    required this.showPercentage,
    required this.onTogglePercentage,
    required this.individualInvestments,
  });

  @override
  _PortfolioOverviewState createState() => _PortfolioOverviewState();
}

class _PortfolioOverviewState extends State<PortfolioOverview> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PortfolioValueNotifier>(
      builder: (context, portfolioValueNotifier, child) {
        bool isZero = portfolioValueNotifier.portfolio.profitOrLoss == 0.00;
        bool isProfit = portfolioValueNotifier.portfolio.profitOrLoss > 0;

        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${portfolioValueNotifier.portfolio.portfolioValue.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: widget.onTogglePercentage,
                            child: Row(
                              children: [
                                Icon(
                                  portfolioValueNotifier
                                              .portfolio.profitOrLoss >
                                          0
                                      ? Icons.keyboard_arrow_up
                                      : (portfolioValueNotifier
                                                  .portfolio.profitOrLoss ==
                                              0.00
                                          ? Icons.keyboard_arrow_right
                                          : Icons.keyboard_arrow_down),
                                  color: portfolioValueNotifier
                                              .portfolio.profitOrLoss >
                                          0
                                      ? Colors.green
                                      : (portfolioValueNotifier
                                                  .portfolio.profitOrLoss ==
                                              0.00
                                          ? Colors.grey
                                          : Colors.red),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable: widget.showPercentage,
                                  builder: (context, value, child) {
                                    String displayValue =
                                        '\$${portfolioValueNotifier.portfolio.profitOrLoss.toStringAsFixed(2)}';
                                    if (value) {
                                      double percentage = portfolioValueNotifier
                                          .portfolio.percentageGainOrLoss;
                                      displayValue = percentage.isNaN
                                          ? '0.00%'
                                          : '${(percentage * 100).ceilToDouble() / 100.0}%';
                                    }
                                    return Text(
                                      displayValue,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: portfolioValueNotifier
                                                    .portfolio.profitOrLoss >
                                                0
                                            ? Colors.green
                                            : (portfolioValueNotifier.portfolio
                                                        .profitOrLoss ==
                                                    0.00
                                                ? Colors.grey
                                                : Colors.red),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            PageRouteBuilder(
                              pageBuilder: (BuildContext context,
                                  Animation<double> animation,
                                  Animation<double> secondaryAnimation) {
                                return HomePageNew();
                              },
                              transitionDuration: Duration.zero,
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(child: widget.individualInvestments),
              ],
            ),
          ),
        );
      },
    );
  }
}

class InvestmentList extends StatefulWidget {
  final List<Map<String, dynamic>> investments;

  InvestmentList(this.investments);

  @override
  _InvestmentListState createState() => _InvestmentListState();
}

class _InvestmentListState extends State<InvestmentList>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _watchlist;
  late PageController _pageController;
  final user = FirebaseAuth.instance.currentUser;
  bool showPercentage = false;
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  Future<List<Map<String, dynamic>>>? _watchlistFuture;

  @override
  void initState() {
    super.initState();

    if (user != null) {
      Provider.of<WatchlistNotifier>(context, listen: false)
          .loadWatchlist(user!.uid);
      _watchlistFuture = PortfolioService().getWatchlist(user!.uid);
      fetchWatchlist();
    }

    _pageController = PageController(initialPage: _currentPage)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      });
  }

  Future<void> fetchWatchlist() async {
    _watchlist = await PortfolioService().getWatchlist(user!.uid);
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(0,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                },
                child: Container(
                  color:
                      _currentPage == 0 ? Colors.grey[300] : Colors.transparent,
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Investments',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _currentPage == 0 ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  _pageController.animateToPage(1,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                },
                child: Container(
                  color:
                      _currentPage == 1 ? Colors.grey[300] : Colors.transparent,
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'Watchlist',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _currentPage == 1 ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            children: [
              // Investments
              widget.investments.isEmpty
                  ? const Center(
                      child: Text(
                        'Here appears your investments',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.investments.length,
                      itemBuilder: (context, index) {
                        var investment = widget.investments[index];
                        bool isInvestmentProfit =
                            investment['profitOrLoss'] > 0;
                        bool isZero = investment['profitOrLoss'] == 0.00;

                        return ListTile(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Share${investment['quantity'].toDouble().toInt() == 1 ? '' : 's'}: ${investment['quantity'].toDouble().toInt()}',
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
                                              : (isZero
                                                  ? Colors.grey
                                                  : Colors.red),
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
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(investment['name']),
                                  content: SingleChildScrollView(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        Expanded(
                                          child: TextButton(
                                            child: Text('Cancel'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ),
                                        // Go To Chart Button
                                        Expanded(
                                          child: TextButton(
                                            child: Text('Go to Chart'),
                                            onPressed: () async {
                                              Navigator.of(context).pop();

                                              final result = await Navigator
                                                  .pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChartStock2(
                                                    title: investment['symbol'],
                                                  ),
                                                ),
                                              );

                                              if (result == 'stateChanged') {
                                                setState(() {});
                                              }
                                            },
                                          ),
                                        ),
                                        // Sell Stock
                                        Expanded(
                                          child: TextButton(
                                            child: Text('Sell Stock'),
                                            onPressed: () async {
                                              // Ask for the amount
                                              int? amount =
                                                  await showDialog<int>(
                                                context: context,
                                                builder: (context) {
                                                  final TextEditingController
                                                      controller =
                                                      TextEditingController();
                                                  return AlertDialog(
                                                    title: const Text(
                                                        'How many shares do you want to sell?'),
                                                    content: TextField(
                                                      controller: controller,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: <TextInputFormatter>[
                                                        FilteringTextInputFormatter
                                                            .allow(
                                                          RegExp(r'[0-9]'),
                                                        ),
                                                      ],
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: 'Amount',
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        child: const Text(
                                                            'Cancel'),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      ),
                                                      TextButton(
                                                        child: const Text('OK'),
                                                        onPressed: () {
                                                          int amount =
                                                              int.tryParse(
                                                                      controller
                                                                          .text) ??
                                                                  0;
                                                          Navigator.of(context)
                                                              .pop(amount);
                                                        },
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                              // Pop the Amount Dialog
                                              // Navigator.of(context).pop();

                                              // Sell stock
                                              if (amount != null) {
                                                // Password Pop Up
                                                String? password =
                                                    await showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return PasswordDialog();
                                                  },
                                                );
                                                FirebaseAuthService auth =
                                                    FirebaseAuthService();
                                                bool correctPassword =
                                                    await auth
                                                        .reauthenticateUser(
                                                            password);
                                                bool success = false;

                                                if (correctPassword) {
                                                  try {
                                                    success =
                                                        await startSellStockFlow(
                                                            amount,
                                                            investment[
                                                                'symbol']);
                                                  } catch (e) {
                                                    print(e); //TODO: DEBUG Line
                                                  }
                                                }

                                                // Refresh page if the stock was successfully sold
                                                if (success) {
                                                  // Find the investment that matches the sold stock
                                                  var soldInvestment = widget
                                                      .investments
                                                      .firstWhere(
                                                    (inv) =>
                                                        inv['symbol'] ==
                                                        investment['symbol'],
                                                    orElse: () =>
                                                        <String, dynamic>{},
                                                  );

                                                  // If the investment was found, decrease its quantity
                                                  if (soldInvestment != null &&
                                                      soldInvestment
                                                          .isNotEmpty) {
                                                    soldInvestment[
                                                        'quantity'] -= amount;
                                                    soldInvestment[
                                                            'totalValue'] -=
                                                        amount *
                                                            soldInvestment[
                                                                'price'];

                                                    // Create an instance of PortfolioService and call calculatePortfolioValue
                                                    PortfolioService
                                                        portfolioService =
                                                        PortfolioService();
                                                    Portfolio updatedPortfolio =
                                                        await portfolioService
                                                            .calculatePortfolioValue(
                                                                user!.uid);

                                                    // Update the PortfolioValueNotifier with the new portfolio
                                                    if (mounted) {
                                                      setState(() {
                                                        var portfolioValueNotifier =
                                                            Provider.of<
                                                                    PortfolioValueNotifier>(
                                                                context,
                                                                listen: false);
                                                        portfolioValueNotifier
                                                            .setPortfolio(
                                                                updatedPortfolio);
                                                      });
                                                    }
                                                  }
                                                }
                                              }
                                              // Close the popup
                                              if (mounted) {
                                                Navigator.of(context).pop();
                                              }
                                            },
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
                      },
                    ),

              Consumer<WatchlistNotifier>(
                builder: (context, watchlistNotifier, child) {
                  var watchlist = watchlistNotifier.watchlist;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: watchlist.isEmpty
                        ? const Center(
                            child: Text(
                              'Watchlist items will appear here when available.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: watchlist.length,
                            itemBuilder: (BuildContext context, int index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChartStock(
                                        title: watchlist[index]['symbol'],
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  title: Text(watchlist[index]['name']),
                                  subtitle: Text(watchlist[index]['symbol']),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String valueToString(bool isProfit, double value) {
    return '${value.toStringAsFixed(2)}';
  }

  String valueToPercentage(bool isProfit, double percentage) {
    return '${percentage.toStringAsFixed(2)}%';
  }
}
