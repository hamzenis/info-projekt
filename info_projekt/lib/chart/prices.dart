import 'dart:convert';
import 'package:http/http.dart' as http;

class ChartData {
  final DateTime time;
  final double price;

  ChartData(this.time, this.price);
}

/*
*
*
*   Fetches data from the API and returns a list of ChartData objects
*/
Future<List<ChartData>> extractDataFromJson() async {
  List<ChartData> spotList = [];

  try {
    // Send a GET request to the API
    String apiKey =
        'cl6hd6hr01qvnck9ogjgcl6hd6hr01qvnck9ogk0'; // Replace with API key
    String url =
        'https://finnhub.io/api/v1/stock/candle?symbol=AAPL&resolution=15&from=1696946340&to=1699714740&token=$apiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $apiKey'});

    // Decode the response body
    Map<String, dynamic> jsonData = json.decode(response.body);

    // [DEBUG ONLY] Load JSON data from the "assets/data.json" file
    // String jsonString = await rootBundle.loadString('assets/data.json');
    // Map<String, dynamic> jsonData = json.decode(jsonString);

    // Extract the Close Prices(Sanitizing INTs) and Timestamps from the JSON data
    List<double> prices = (jsonData["c"] as List)
        .map((item) => double.parse(item.toString()))
        .toList();

    List<int> timestamps = List<int>.from(jsonData["t"] ?? []);

    for (int i = 0; i < prices.length; i++) {
      spotList.add(ChartData(
          DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
          prices[i]));
    }
  } catch (e) {
    print(
        "Error parsing JSON: $e"); // TODO: Remove and replace with error handling
  }

  return spotList;
}
