// ignore_for_file: slash_for_doc_comments

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/portfolio_service.dart';
import '../services/stockData_service.dart';
import '../widgets/watchlist_button.dart';

import '../widgets/buy_popup.dart';

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
  String selectedTimeRange = 'month'; // Default to 'month'
  bool isInWatchlist = false;
  final portfolioService = PortfolioService();

  /** 
  *  
  *
  */
  @override
  void initState() {
    _zoomPanBehavior = ZoomPanBehavior(
        // Enables pinch zooming
        enablePinching: true);
    super.initState();
    updateUid();
    checkIfInWatchlist();
  }

  void updateUid() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      uid = user?.uid;
    });
  }

  /**
  *   TODO: Rewrite as Container not Widget
  *   Build price container under chart
  */
  Widget buildPriceContainer(String realTimeQuote) {
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

  Future<void> checkIfInWatchlist() async {
    isInWatchlist =
        await portfolioService.checkIfInWatchlist(uid!, widget.title);
  }

  /**
  *
  *
  *
  *
  *   
  */
  @override
  Widget build(BuildContext context) {
    /*
    *
    *
    */
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
            List<ChartData> spotListMonthly = snapshot.data![0];
            String companyName = snapshot.data![1];
            String realTimeQuote = snapshot.data![2];
            currentData = spotListMonthly;
            String companyAbout = snapshot.data![3];

            return Scaffold(
                appBar: AppBar(
                  title: Text(widget.title),
                  actions: <Widget>[
                    FutureBuilder<bool>(
                      future: portfolioService.checkIfInWatchlist(
                          uid!, widget.title),
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
                      Container(
                        // Company name Container
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          companyName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        child: _buildChart(),
                      ),
                      Row(
                        // Buttons Row
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _updateChartData('year');
                            },
                            child: const Text('Year'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateChartData('month');
                            },
                            child: const Text('Month'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _updateChartData('day');
                            },
                            child: const Text('Day'),
                          ),
                        ],
                      ),
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
                        return BuyPopup(
                          stockSymbol: widget.title,
                        ); // Show the BuyPopup content
                      },
                    );
                  },
                  backgroundColor: Colors.green,
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Buy'),
                ));
          } else {
            return const Text('No data'); // TODO: Replace with error handling
          }
        }
      },
    );
  }

  /**
   * 
   * 
   * 
   * 
   * 
   * 
   * 
   */
  Future<List<dynamic>> _getData() async {
    switch (selectedTimeRange) {
      case 'year':
        return Future.wait([
          loadYearData(widget.title),
          getCompanyName(widget.title),
          getCurrentPrice(widget.title),
          getCompanyAbout(widget.title),
        ]);
      case 'month':
        return Future.wait([
          loadMonthData(widget.title),
          getCompanyName(widget.title),
          getCurrentPrice(widget.title),
          getCompanyAbout(widget.title),
        ]);
      case 'day':
        return Future.wait([
          loadDayData(widget.title),
          getCompanyName(widget.title),
          getCurrentPrice(widget.title),
          getCompanyAbout(widget.title),
        ]);
      default:
        return [];
    }
  }

  /**
   * 
   * 
   * 
   * Function to call the API and get the data
   * 
   */
  void _updateChartData(String timeRange) {
    setState(() {
      selectedTimeRange = timeRange;
    });
  }

  /**
   * 
   * 
   * 
   * 
   * Builds the chart widget
   */
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

  /**
   * 
   * 
   * 
   * Returns the list of chart series which need to render
   * on the update data source chart.
   */
  List<ChartSeries<ChartData, DateTime>> _getUpdateDataSourceSeries() {
    return <ChartSeries<ChartData, DateTime>>[
      // Renders line chart
      LineSeries<ChartData, DateTime>(
          dataSource: currentData!,
          xValueMapper: (ChartData data, _) => data.time,
          yValueMapper: (ChartData data, _) => data.price)
    ];
  }

/**
 * 
 * 
 * 
 */
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
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /**
   * 
   * 
   * 
   * 
   */
  @override
  void dispose() {
    currentData!.clear();
    super.dispose();
  }
}
