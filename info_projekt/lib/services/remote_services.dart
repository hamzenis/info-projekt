import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:info_projekt/models/news.dart';

class RemoteService {
  // Replace 'YOUR_API_KEY' with your actual Finnhub API key.
  final String apiKey = 'cl7rdopr01qqqm01c250cl7rdopr01qqqm01c25g';

  Future<List<News>?> getNews() async {
    var client = http.Client();

    var uri = Uri.parse(
        'https://finnhub.io/api/v1/news?category=forex&token=$apiKey');

    var response = await client.get(uri);

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      List<News> newsList = [];

      for (var newsItem in jsonResponse) {
        newsList.add(News.fromJson(newsItem));
      }

      return newsList;
    } else {
      throw Exception('Failed to load market news');
    }
  }
}
