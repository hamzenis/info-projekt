import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'prices.dart';

class ChartStock extends StatefulWidget {
  const ChartStock({super.key});

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
*   Zooming Feature 
*/
  late ZoomPanBehavior _zoomPanBehavior;
/*
*  
*
*
*
*   Chart Featuress
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
*
*
*
*   
*/
  @override
  Widget build(BuildContext context) {
    /*
    *
    *   If it's weekend, the chart will be 'greyed out'
    */
    List<PlotBand> plotBands = [];
    for (int year = 2023; year <= 2025; year++) {
      // TODO: Replace with year of first data point
      for (int month = 1; month <= 12; month++) {
        for (int day = 1; day <= DateTime(year, month + 1, 0).day; day++) {
          DateTime date = DateTime(year, month, day);
          if (date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday) {
            plotBands.add(
              PlotBand(
                isVisible: true,
                opacity: 0.5,
                start: date,
                end: date.add(Duration(days: 1)),
                color: Color.fromARGB(128, 73, 148, 236),
              ),
            );
          }
        }
      }
    }

    /*
    *
    *
    *
    *
    */
    return FutureBuilder<List<ChartData>>(
      future: extractDataFromJson(),
      builder: (BuildContext context, AsyncSnapshot<List<ChartData>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // TODO: Fix show a loading spinner while waiting
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          if (snapshot.data != null) {
            List<ChartData> spotList = snapshot.data!;
            return Scaffold(
              appBar: AppBar(
                title: Text('Aktie'), // TODO: Replace with Aktiennamen
              ),
              body: Container(
                height: 700,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(40),
                      child: const Text(
                        // TODO: Replace with Aktiennamen from search
                        'AAPL - Apple Inc.',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SfCartesianChart(
                      primaryXAxis:
                          DateTimeAxis(plotBands: plotBands), // Date axis
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
                    ),
                    Container(
                      padding: EdgeInsets.all(40),
                      child: const Text(
                        // TODO: Replace with current price
                        '180,56\$',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
