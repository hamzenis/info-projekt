import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/portfolio_service.dart';
import 'package:info_projekt/services/stockData_service.dart';
import 'package:info_projekt/widgets/watchlist_button.dart';
import 'package:info_projekt/widgets/buy_popup.dart';

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

                    buildAboutContainer(companyAbout),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      // Show the BuyPopup content
                      return BuyPopup(
                        stockSymbol: widget.title,
                      );
                    },
                  );
                },
                backgroundColor: Colors.green,
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

  /// Container for the company about
  Container buildAboutContainer(String companyAbout) {
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
          Text(
            companyAbout,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    currentData!.clear();
    super.dispose();
  }
}
