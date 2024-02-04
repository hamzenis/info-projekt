import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/portfolio_service.dart';
import 'package:info_projekt/services/stockData_service.dart';
import 'package:info_projekt/widgets/watchlist_button.dart';
import 'package:info_projekt/widgets/buy_popup.dart';
import 'package:info_projekt/globals.dart';

class ChartStock extends StatefulWidget {
  final String title;
  const ChartStock({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<ChartStock> createState() => _ChartStockState();
}

class _ChartStockState extends State<ChartStock> {
  late ZoomPanBehavior _zoomPanBehavior;
  String? uid;
  List<ChartData>? currentData;
  bool isInWatchlist = false;
  final portfolioService = PortfolioService();
  bool boolMarketOpen = false;

  @override
  void initState() {
    // Enables pinch zooming
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
    );
    super.initState();
    updateUid();
    checkIfInWatchlist();
  }

  /// Updates the uid
  void updateUid() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      uid = user?.uid;
    });
  }

  /// Container for the price
  Container buildPriceContainer(String realTimeQuote) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Text(
        '$realTimeQuote\$',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Check if the stock is in the watchlist
  Future<void> checkIfInWatchlist() async {
    isInWatchlist = await portfolioService.checkIfInWatchlist(
      uid!,
      widget.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _getData(),
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.white,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          if (snapshot.data != null) {
            List<ChartData> chartDataList = snapshot.data![0];
            String companyName = snapshot.data![1];
            String realTimeQuote = snapshot.data![2];
            currentData = chartDataList;
            String companyAbout = snapshot.data![3];
            bool isExpanded = false;
            boolMarketOpen = snapshot.data![6];

            return Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
                actions: <Widget>[
                  FutureBuilder<bool>(
                    future:
                        portfolioService.checkIfInWatchlist(uid!, widget.title),
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      if (snapshot.hasData) {
                        return WatchlistButton(
                          isInWatchlist: snapshot.data!,
                          title: widget.title,
                          companyName: companyName,
                          uid: uid!,
                        );
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Check if the market is open
                    if (!boolMarketOpen) buildExchangeStatusRow(),

                    // Company name Container
                    Container(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Chart and Button Container
                    // StatefulBuilder to rebuild the chart
                    StatefulBuilder(builder: (context, setState) {
                      return Column(
                        children: [
                          // Chart Container
                          Container(
                            child: _buildChart(),
                          ),
                          // Buttons Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    currentData = <ChartData>[];
                                    currentData = snapshot.data![5];
                                  });
                                },
                                child: const Text('Year'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    currentData = <ChartData>[];
                                    currentData = snapshot.data![0];
                                  });
                                },
                                child: const Text('Month'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    currentData = <ChartData>[];
                                    currentData = snapshot.data![4];
                                  });
                                },
                                child: const Text('Day'),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),

                    buildPriceContainer(realTimeQuote),

                    // About Container with Tap to Expand feature
                    StatefulBuilder(builder: (context, setState) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "About",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: isExpanded
                                      ? companyAbout
                                      : (companyAbout.substring(0, 100) +
                                          ' ...Tap to Expand'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  if (boolMarketOpen || overrideMarketOpen) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        // Show the BuyPopup content
                        return BuyPopup(
                          stockSymbol: widget.title,
                        );
                      },
                    );
                  }
                },
                backgroundColor: boolMarketOpen || overrideMarketOpen
                    ? Colors.green
                    : Colors.green.withAlpha(100),
                icon: const Icon(Icons.attach_money),
                label: const Text('Buy'),
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
              ),
              body: const Center(
                child: Text('No data available'),
              ),
            );
          }
        }
      },
    );
  }

  /// Returns Exchange Opening Status
  LayoutBuilder buildExchangeStatusRow() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: constraints.maxWidth * 0.8,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                children: [
                  const Text(
                    "Exchange (NYSE) is closed",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "You can place orders when the market reopens",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (overrideMarketOpen)
                    const Text(
                      "(Override Global active)",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Gets the chart data based on the selected time range
  /// Load ahead strategy is used to load the chart data
  /// Return: Future<List<dynamic>> snapshot
  Future<List<dynamic>> _getData() async {
    return Future.wait([
      loadMonthData(widget.title),
      getCompanyName(widget.title),
      getCurrentPrice(widget.title),
      getCompanyAbout(widget.title),
      loadDayData(widget.title),
      loadYearData(widget.title),
      isMarketOpen(),
    ]);
  }

  /// Builds the chart
  SfCartesianChart _buildChart() {
    return SfCartesianChart(
      primaryXAxis: DateTimeCategoryAxis(), // Date axis
      primaryYAxis: NumericAxis(
        // Applies currency format for y axis labels and also for data labels
        numberFormat: NumberFormat.simpleCurrency(),
      ),
      zoomPanBehavior: _zoomPanBehavior, // Zoom and pan feature
      series: _getUpdateDataSourceSeries(),
    );
  }

  /// Returns the list of chart series which need to render
  /// on the update data source chart.
  /// Opacity is set to 0.7 to make the series color light.
  /// Color is set to the primary color of the app.
  List<AreaSeries<ChartData, DateTime>> _getUpdateDataSourceSeries() {
    return <AreaSeries<ChartData, DateTime>>[
      AreaSeries<ChartData, DateTime>(
        opacity: 0.7,
        color: Theme.of(context).primaryColor,
        dataSource: currentData!,
        xValueMapper: (ChartData data, _) => data.time,
        yValueMapper: (ChartData data, _) => data.price,
      )
    ];
  }

  @override
  void dispose() {
    currentData!.clear();
    super.dispose();
  }
}
