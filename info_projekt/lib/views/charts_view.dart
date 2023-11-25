import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/prices.dart';

class ChartStock extends StatefulWidget {
  final String title;
  const ChartStock({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<ChartStock> createState() => _ChartStockState();
}

/*
*   Meine Augen brennen bitte nicht alles auf einen Fleck
*
*
*
*
*/
class _ChartStockState extends State<ChartStock> {
/*
*  
*   
*/
  late ZoomPanBehavior _zoomPanBehavior;
  List<ChartData>? currentData;

/*
*  
*
*/
  @override
  void initState() {
    _zoomPanBehavior = ZoomPanBehavior(
        // Enables pinch zooming
        enablePinching: true);
    super.initState();
  }

/*
*
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

/*
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
      future: Future.wait([
        extractDataFromJson(widget.title),
        getCompanyName(widget.title),
        extractRealTimeQuote(widget.title),
        loadDayData(widget.title),
      ]),
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

            return Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
              ),
              body: SizedBox(
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
                          onPressed: () {},
                          child: const Text('Year'),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Month'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Press this button to update the chart data source and display new chart
                          },
                          child: const Text('Day'),
                        ),
                      ],
                    ),
                    buildPriceContainer(realTimeQuote),
                  ],
                ),
              ),
            );
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
 * 
 * 
 * 
 */

/**
 * 
 * 
 * 
 * 
 * 
 * 
 * 
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

  @override
  void dispose() {
    currentData!.clear();
    super.dispose();
  }
}
