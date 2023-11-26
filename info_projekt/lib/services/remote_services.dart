import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:info_projekt/models/news.dart';

class RemoteService {
  final String apiKey = 'KKCRslaWI36ENKmv2yKfduM44Z5EDm0X';

  Future<List<News>?> getNews() async {
    var client = http.Client();

    var uri = Uri.parse(
        'https://financialmodelingprep.com/api/v3/stock_news?page=0&apikey=$apiKey');

    var response = await client.get(uri);

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      List<News> newsList = [];

      if (jsonResponse is Map<String, dynamic>) {
        var articles = jsonResponse['News'] as List<dynamic>?;
        if (articles != null) {
          newsList = postFromJson(jsonEncode(articles));
        }
      } else if (jsonResponse is List<dynamic>) {
        newsList = postFromJson(jsonEncode(jsonResponse));
      }
      return newsList;
      //for (var newsItem in jsonResponse) {
      //newsList.add(News.fromJson(newsItem));
    } else {
      throw Exception('Failed to load market news');
    }
  }
}
