import 'dart:convert';
import 'package:http/http.dart' as http;

// TODO: Remove API key from code
// TODO: Add error handling
// TODO: Replace Day data request for a better resolution (1min or 5min)
// TODO: Check if it's weekend/after hours/holidays and return other chart data (day data)
// TODO: Write documentation
String apiKey = 'KKCRslaWI36ENKmv2yKfduM44Z5EDm0X';

class ChartData {
  final DateTime time;
  final double price;

  ChartData(this.time, this.price);
}

/*
*
*
*   Fetches data from the API and returns a list of ChartData objects
*   The list contains the Close Price and Timestamp for each hour
*/
Future<List<ChartData>> loadMonthData(String stockSymbol) async {
  List<ChartData> spotList = [];
  DateTime today = DateTime.now();
  DateTime lastMonth = today.subtract(Duration(days: 30));
  String todayString = today.toString().substring(0, 10);
  String lastMonthString = lastMonth.toString().substring(0, 10);

  try {
    // Send a GET request to the API
    String url =
        'https://financialmodelingprep.com/api/v3/historical-chart/1hour/$stockSymbol?from=$lastMonthString&to=$todayString&apikey=$apiKey';
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
    throw ("Error parsing JSON: $e"); // TODO: Remove and replace with error handling
  }

  return spotList;
}

/*
*
*   TODO: Return a double instead of a String
*   Fetches data from the API and returns a double with the real-time quote price
*/
Future<String> getCurrentPrice(String stockSymbol) async {
  double realTimeQuote = 0.0;

  try {
    String url =
        'https://financialmodelingprep.com/api/v3/quote-short/$stockSymbol?apikey=$apiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $apiKey'});

    // Decode the response body
    List<dynamic> jsonData = json.decode(response.body);

    // Extract the real-time quote
    realTimeQuote = double.parse(jsonData[0]['price'].toString());
    // Limit the number of decimals to 2
    realTimeQuote = double.parse(realTimeQuote.toStringAsFixed(2));
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
  String companyName = '';

  try {
    String url =
        'https://financialmodelingprep.com/api/v3/profile/$stockSymbol?apikey=$apiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $apiKey'});

    // Decode the response body
    List<dynamic> jsonData = json.decode(response.body);

    // Extract the company name
    companyName = jsonData[0]['companyName'].toString();
  } catch (e) {
    // Handle the exception
    print('Error parsing JSON: $e');
  }
  return companyName;
}

/*
*
*
*   Fetches data from the API and returns a list of ChartData objects
*   The list contains the Close Price and Timestamp for each 15mins
*/
Future<List<ChartData>> loadDayData(String stockSymbol) async {
  List<ChartData> spotList = [];
  DateTime todaya = DateTime.now();
  DateTime today = todaya.subtract(Duration(days: 2));
  String todayString = today.toString().substring(0, 10);

  try {
    String url =
        'https://financialmodelingprep.com/api/v3/historical-chart/15min/$stockSymbol?from=$todayString&to=$todayString&apikey=$apiKey';
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
*   Fetches data from the API and returns a list of ChartData objects
*   The list contains the Close Price and Timestamp for each day
*/
Future<List<ChartData>> loadYearData(String stockSymbol) async {
  List<ChartData> spotList = [];
  DateTime today = DateTime.now();
  DateTime lastYear = today.subtract(Duration(days: 365));
  String todayString = today.toString().substring(0, 10);
  String lastYearString = lastYear.toString().substring(0, 10);

  try {
    String url =
        'https://financialmodelingprep.com/api/v3/historical-chart/1day/$stockSymbol?from=$lastYearString&to=$todayString&apikey=$apiKey';
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

/**
 * 
 * 
 * 
 * 
 */
Future<String> getCompanyAbout(String stockSymbol) async {
  String companyAbout = '';

  try {
    String url =
        'https://financialmodelingprep.com/api/v3/profile/$stockSymbol?apikey=$apiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $apiKey'});

    // Decode the response body
    List<dynamic> jsonData = json.decode(response.body);

    // Extract the company about description
    companyAbout = jsonData[0]['description'].toString();
  } catch (e) {
    // Handle the exception
    print('Error parsing JSON: $e');
  }
  // insertNewLine(companyAbout);
  return companyAbout;
}

/**
 * TODO: Check if this function is needed
 * Helper for the About Container
 * Inserts a new line after every ; char
 */
String insertNewLine(String companyAbout) {
  String newText = '';
  for (int i = 0; i < companyAbout.length; i++) {
    if (companyAbout[i] == ';') {
      newText += '\n';
    } else {
      newText += companyAbout[i];
    }
  }
  return newText;
}
Future<bool> isMarketOpen() async {
  String url = 'https://financialmodelingprep.com/api/v3/is-the-market-open?apikey=$apiKey';
  http.Response response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $apiKey'});

  // Decode the response body
  Map<String, dynamic> jsonData = json.decode(response.body);

  // Extract the market status
  bool isMarketOpen = jsonData['isTheStockMarketOpen'];

  return isMarketOpen;
}
