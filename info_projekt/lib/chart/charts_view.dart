import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'prices.dart';

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
  late String realTimeQuote;
  late String companyName;

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
    fetchRealTimeQuote(widget.title);
    fetchCompanyName(widget.title);
  }

/*
*   Fetches the real-time quote from the API
*/
  Future<void> fetchRealTimeQuote(String title) async {
    realTimeQuote = await extractRealTimeQuote(title);
  }

/*
*   Fetches the real-time quote from the API
*/
  Future<void> fetchCompanyName(String title) async {
    companyName = await getCompanyName(title);
  }

/*
*
*   Fetches monthly data from prices.dart
*/
  // FutureBuilder<List<ChartData>> buildMonthly() {}

/* 
*   Builds the chart
*
*/
  Widget buildChart(List<ChartData> spotList) {
    return SfCartesianChart(
      primaryXAxis: DateTimeCategoryAxis(), // Date axis
      primaryYAxis: NumericAxis(
        // Applies currency format for y axis labels and also for data labels
        numberFormat: NumberFormat.simpleCurrency(),
      ),
      zoomPanBehavior: _zoomPanBehavior, // Zoom and pan feature
      series: <ChartSeries<ChartData, DateTime>>[
        // Renders line chart
        LineSeries<ChartData, DateTime>(
            dataSource: spotList,
            xValueMapper: (ChartData data, _) => data.time,
            yValueMapper: (ChartData data, _) => data.price)
      ],
    );
  }

/*
*
*   Build price container under chart
*/
  Widget buildPriceContainer() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Text(
        realTimeQuote + '\$',
        style: TextStyle(
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
    List<ChartData> spotList = [];
    /*
    *
    *
    *
    *
    */
    return FutureBuilder<List<ChartData>>(
      future: extractDataFromJson(widget.title),
      builder: (BuildContext context, AsyncSnapshot<List<ChartData>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          if (snapshot.data != null) {
            List<ChartData> spotList = snapshot.data!;
            return Scaffold(
              appBar: AppBar(
                title: Text(widget.title),
              ),
              body: SizedBox(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      // TODO: Add functionality to buttons
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            // Handle Button Press
                          },
                          child: const Text('Year'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Handle button press
                          },
                          child: const Text('Month'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Handle button press
                          },
                          child: const Text('Day'),
                        ),
                      ],
                    ),
                    buildChart(spotList),
                    buildPriceContainer(),
                  ],
                ),
              ),
            );
          } else {
            return Text('No data'); // TODO: Replace with error handling
          }
        }
      },
    );
  }
}
