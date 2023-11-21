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
Future<List<ChartData>> extractDataFromJson(String stockSymbol) async {
  List<ChartData> spotList = [];

  try {
    // Send a GET request to the API
    String apiKey =
        'cl6hd6hr01qvnck9ogjgcl6hd6hr01qvnck9ogk0'; // Replace with API key
    String url =
        'https://finnhub.io/api/v1/stock/candle?symbol=$stockSymbol&resolution=15&from=1696946340&to=1699714740&token=$apiKey';
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

/*
*
*
*   Fetches data from the API and returns a double with the real-time quote price
*/
Future<String> extractRealTimeQuote(String stockSymbol) async {
  double realTimeQuote = 0.0;

  try {
    // Send a GET request to the API
    String apiKey = 'cl6hd6hr01qvnck9ogjgcl6hd6hr01qvnck9ogk0';
    String url =
        'https://finnhub.io/api/v1/quote?symbol=$stockSymbol&token=$apiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $apiKey'});

    // Decode the response body
    Map<String, dynamic> jsonData = json.decode(response.body);

    // Extract the real-time quote
    realTimeQuote = double.parse(jsonData['c'].toString());
  } catch (e) {
    // Handle the exception
    print(
        'Error parsing JSON: $e'); // TODO: Remove and replace with error handling
  }

  return realTimeQuote.toString();
}

/*
*
*
*   Gets the company name from the API and returns a String
*/
Future<String> getCompanyName(String stockSymbol) async {
  String companyName = "";

  try {
    // Send a GET request to the API
    String apiKey = 'cl6hd6hr01qvnck9ogjgcl6hd6hr01qvnck9ogk0';
    String url =
        'https://finnhub.io/api/v1/stock/profile2?symbol=$stockSymbol&token=$apiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $apiKey'});

    // Decode the response body
    Map<String, dynamic> jsonData = json.decode(response.body);

    // Extract the real-time quote
    companyName = jsonData['name'].toString();
  } catch (e) {
    // Handle the exception
    print('Error parsing JSON: $e');
  }
  return companyName;
}
