import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class SearchService {
  void Function(List<dynamic>) onSearchResults;

  SearchService({required this.onSearchResults});

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
