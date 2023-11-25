import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// The Brain of the Search Page.
/// This class is responsible for fetching the search results and the stock data.
/// It works with the [SearchPage] class to create the Search Page View.
class SearchService {
  void Function(List<dynamic>) onSearchResults;

  SearchService({required this.onSearchResults});

  /// Function to fetch the search results.
  /// It uses the [http] package to make the API call.
  /// It uses the [jsonDecode] function to decode the response.
  /// It uses the [where] function to filter out the results that are not stocks.
  /// It uses the [toList] function to convert the results to a list.
  /// It uses the [onSearchResults] callback function to update the search results.
  /// It throws an exception if the API call fails.
  Future<void> fetchSearchResults(String query) async {
    final response = await http.get(Uri.parse(
        'https://financialmodelingprep.com/api/v3/search?query=$query&apikey=KKCRslaWI36ENKmv2yKfduM44Z5EDm0X'));

    if (response.statusCode == 200) {
      var results = jsonDecode(response.body);
      var filteredResults = results.where((result) {
        return !result['symbol'].contains('.');
      }).toList();

      // Use the callback function to update the search results
      onSearchResults(filteredResults);
    } else {
      throw Exception('Failed to load search results');
    }
  }

  /// Function to fetch the stock data.
  /// It uses the [DefaultCacheManager] class to cache the API response.
  /// It uses the [getSingleFile] function to get the cached file.
  /// It uses the [readAsString] function to read the cached file as a string.
  /// It uses the [jsonDecode] function to decode the response.
  /// It returns the stock data as a [Map].
  /// It throws an exception if the API call fails.
  Future<Map<String, dynamic>> fetchStock(String symbol) async {
    final cacheManager = DefaultCacheManager();
    final file = await cacheManager.getSingleFile(
        'https://financialmodelingprep.com/api/v3/profile/$symbol?apikey=KKCRslaWI36ENKmv2yKfduM44Z5EDm0X');
    if (file != null && await file.exists()) {
      var res = await file.readAsString();
      var jsonResponse = jsonDecode(res);
      return jsonResponse[0];
    }
    throw Exception('Failed to load stock');
  }
}
