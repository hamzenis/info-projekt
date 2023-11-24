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
    String apiKey = 'KKCRslaWI36ENKmv2yKfduM44Z5EDm0X'; // Replace with API key
    String url =
        'https://financialmodelingprep.com/api/v3/historical-chart/1hour/AAPL?from=2023-10-24&to=2023-11-24&apikey=$apiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $apiKey'});

    // Decode the response body
    List<dynamic> jsonDataList = json.decode(response.body);

    // Reverse the list, because the API returns the data in descending order
    jsonDataList = jsonDataList.reversed.toList();

    for (var jsonData in jsonDataList) {
      // Extract the Close Price and Timestamp from the JSON data
      double price = double.parse(jsonData["close"].toString());
      String timeString = jsonData["date"].toString();

      // Add the data to the spotList
      spotList.add(ChartData(DateTime.parse(timeString), price));
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
