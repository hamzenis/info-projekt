import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:info_projekt/globals.dart';

class ChartData {
  final DateTime time;
  final double price;

  ChartData(this.time, this.price);
}

/// Fetches data from the API for the last month
/// Return: List<ChartData> spotList (Close Price and Timestamp for each hour)
Future<List<ChartData>> loadMonthData(String stockSymbol) async {
  List<ChartData> spotList = [];
  DateTime today = DateTime.now();
  DateTime lastMonth = today.subtract(Duration(days: 30));
  String todayString = today.toString().substring(0, 10);
  String lastMonthString = lastMonth.toString().substring(0, 10);

  try {
    // Send a GET request to the API
    String url =
        'https://financialmodelingprep.com/api/v3/historical-chart/1hour/$stockSymbol?from=$lastMonthString&to=$todayString&apikey=$fmgApiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $fmgApiKey'});
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
    throw ("Error parsing JSON: $e");
  }

  return spotList;
}

/// Fetches current price from the API
/// Return: String realTimeQuote (Current price of the stock)
Future<String> getCurrentPrice(String stockSymbol) async {
  double realTimeQuote = 0.0;

  try {
    String url =
        'https://financialmodelingprep.com/api/v3/quote-short/$stockSymbol?apikey=$fmgApiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $fmgApiKey'});
    List<dynamic> jsonData = json.decode(response.body);

    realTimeQuote = double.parse(jsonData[0]['price'].toString());
    realTimeQuote = double.parse(realTimeQuote.toStringAsFixed(2));
  } catch (e) {
    throw ('Error parsing JSON: $e');
  }
  return realTimeQuote.toString();
}

/// Fetches company name from the API
/// Return: String companyName (Name of the company)
Future<String> getCompanyName(String stockSymbol) async {
  String companyName = '';
  try {
    String url =
        'https://financialmodelingprep.com/api/v3/profile/$stockSymbol?apikey=$fmgApiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $fmgApiKey'});
    List<dynamic> jsonData = json.decode(response.body);

    companyName = jsonData[0]['companyName'].toString();
  } catch (e) {
    // Handle the exception
    throw ('Error parsing JSON: $e');
  }
  return companyName;
}

/// Fetches data from the API for the last day
/// Return: List<ChartData> spotList (Close Price and Timestamp for each 15 minutes)
Future<List<ChartData>> loadDayData(String stockSymbol) async {
  List<ChartData> spotList = [];
  DateTime today = DateTime.now();

  // Api dont give data for weekends or when its Monday before 9:30 AM GMT-5
  // So we need to check if its weekend or if its Monday before 9:30 AM GMT-5
  // If it is, we need to get data from Friday
  switch (today.weekday) {
    case == DateTime.sunday:
      today = today.subtract(Duration(days: 2));
      break;

    case == DateTime.saturday:
      today = today.subtract(Duration(days: 1));
      break;

    case == DateTime.monday:
      // In our time zone (GMT+1) the NYSE market opens at 15:30
      if (today.hour < 15 || (today.hour == 15 && today.minute < 30)) {
        today = today.subtract(Duration(days: 3));
      }
      break;

    default:
      break;
  }
  String todayString = today.toString().substring(0, 10);
  try {
    String url =
        'https://financialmodelingprep.com/api/v3/historical-chart/15min/$stockSymbol?from=$todayString&to=$todayString&apikey=$fmgApiKey';

    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $fmgApiKey'});
    List<dynamic> jsonDataList = json.decode(response.body);

    // Reverse the list, because the API returns the data in descending order
    jsonDataList = jsonDataList.reversed.toList();

    for (var jsonData in jsonDataList) {
      // Extract the Close Price and Timestamp from the JSON data
      double price = double.parse(jsonData["close"].toString());
      String timeString = jsonData["date"].toString();

      spotList.add(ChartData(DateTime.parse(timeString), price));
    }
  } catch (e) {
    throw ("Error parsing JSON: $e");
  }
  return spotList;
}

/// Fetches data from the API for the last year
/// Return: List<ChartData> spotList (Close Price and Timestamp for each day)
Future<List<ChartData>> loadYearData(String stockSymbol) async {
  List<ChartData> spotList = [];
  DateTime today = DateTime.now();
  DateTime lastYear = today.subtract(Duration(days: 365));
  String todayString = today.toString().substring(0, 10);
  String lastYearString = lastYear.toString().substring(0, 10);

  try {
    String url =
        'https://financialmodelingprep.com/api/v3/historical-chart/1day/$stockSymbol?from=$lastYearString&to=$todayString&apikey=$fmgApiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $fmgApiKey'});
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
    throw ("Error parsing JSON: $e");
  }
  return spotList;
}

/// Fetches company about from the API
/// Return: String companyAbout (Description of the company)
Future<String> getCompanyAbout(String stockSymbol) async {
  String companyAbout = '';

  try {
    String url =
        'https://financialmodelingprep.com/api/v3/profile/$stockSymbol?apikey=$fmgApiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $fmgApiKey'});
    List<dynamic> jsonData = json.decode(response.body);

    companyAbout = jsonData[0]['description'].toString();
  } catch (e) {
    throw ('Error parsing JSON: $e');
  }
  return companyAbout;
}

/// Fetches the market status from the API
/// Return: bool isMarketOpen (True if the market is open, false if it is closed)
Future<bool> isMarketOpen() async {
  bool isMarketOpen = false;
  try {
    String url =
        'https://financialmodelingprep.com/api/v3/is-the-market-open?apikey=$fmgApiKey';
    http.Response response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $fmgApiKey'});
    Map<String, dynamic> jsonData = json.decode(response.body);

    // Extract the market status
    isMarketOpen = jsonData['isTheStockMarketOpen'];
  } catch (e) {
    throw ('Error parsing JSON: $e');
  }

  return isMarketOpen;
}
