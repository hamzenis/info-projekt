import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/pages/profile_page.dart';
import 'package:info_projekt/views/charts_view.dart';
import 'package:info_projekt/views/wallet_screen.dart';
import 'dart:math' as math;
import 'views/search_view.dart';
import 'views/newspage.dart';
import 'services/portfolio_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePageNew extends StatelessWidget {
  static const _actionTitles = ['Search', 'News', 'Profile', 'Wallet'];
  final PortfolioService portfolioService = PortfolioService();

  HomePageNew({super.key});

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
        });
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SearchPage(
                          title: 'Search Page',
                        )),
              );
            },
            icon: const Icon(Icons.search),
          ),
          ActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewsPage()),
              );
            },
            icon: const Icon(Icons.newspaper),
          ),
          ActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(
                        // title: "User Profile",
                        )),
              );
            },
            icon: const Icon(Icons.person),
          ),
          ActionButton(
            onPressed: () {
              // TODO: Remove shortcut to chart
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WalletScreen()),
              );
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
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    return user == null
        ? Center(child: Text('Please log in'))
        : FutureBuilder<Map<String, dynamic>>(
            future: portfolioService.calculatePortfolioValue(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return SafeArea(
                  child: PortfolioOverview(
                    portfolioValue: snapshot.data!['portfolioValue'],
                    profitOrLoss: snapshot.data!['profitOrLoss'],
                    percentageGainOrLoss:
                        snapshot.data!['percentageGainOrLoss'],
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
                  ),
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

class PortfolioOverview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    bool isProfit = profitOrLoss >= 0;

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '\$${portfolioValue.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: onTogglePercentage,
              child: Row(
                children: [
                  Icon(
                    isProfit
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isProfit ? Colors.green : Colors.red,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: showPercentage,
                    builder: (context, value, child) {
                      return Text(
                        value
                            ? '${percentageGainOrLoss.toStringAsFixed(2)}%'
                            : '\$${profitOrLoss.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          color: isProfit ? Colors.green : Colors.red,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Expanded(child: individualInvestments),
          ],
        ),
      ),
    );
  }
}

class InvestmentList extends StatefulWidget {
  final List<Map<String, dynamic>> investments;

  InvestmentList(this.investments);

  @override
  _InvestmentListState createState() => _InvestmentListState();
}

class _InvestmentListState extends State<InvestmentList> {
  late PageController _pageController;
  final user = FirebaseAuth.instance.currentUser;
  bool showPercentage = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              ListView.builder(
                itemCount: widget.investments.length,
                itemBuilder: (context, index) {
                  var investment = widget.investments[index];
                  bool isInvestmentProfit = investment['profitOrLoss'] >= 0;

                  return ListTile(
                    title: Text(investment['name']),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${investment['totalValue'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color:
                                isInvestmentProfit ? Colors.green : Colors.red,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showPercentage = !showPercentage;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(
                                isInvestmentProfit
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: isInvestmentProfit
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              Text(
                                showPercentage
                                    ? '${valueToPercentage(isInvestmentProfit, investment['percentageGainOrLoss'])}'
                                    : '\$${valueToString(isInvestmentProfit, investment['profitOrLoss'])}',
                                style: TextStyle(
                                  color: isInvestmentProfit
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Watchlist
              FutureBuilder<List<Map<String, dynamic>>>(
                future: PortfolioService().getWatchlist(user!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    var watchlist = snapshot.data;
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: watchlist!.isEmpty
                          ? Text(
                              'Watchlist items will appear here when available.',
                              style: TextStyle(color: Colors.grey),
                            )
                          : ListView.builder(
                              itemCount: watchlist.length,
                              itemBuilder: (context, index) {
                                return FutureBuilder(
                                  future: http.get(Uri.parse(
                                      'https://financialmodelingprep.com/api/v3/profile/${watchlist[index]['symbol']}?apikey=KKCRslaWI36ENKmv2yKfduM44Z5EDm0X')),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    } else {
                                      var stockData =
                                          jsonDecode(snapshot.data!.body)[0];
                                      return Container(
                                        child: ListTile(
                                          title: Text(watchlist[index]['name']),
                                          subtitle:
                                              Text('\$${stockData['price']}'),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ChartStock(
                                                  title: watchlist[index]
                                                      ['symbol'],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    );
                  }
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
