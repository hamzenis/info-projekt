import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chart/charts_view.dart';

class SearchPage extends StatefulWidget {
  final String title;

  const SearchPage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  _SearchPage createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  List<dynamic> _searchResults = [];

  Future<void> fetchSearchResults(String query) async {
    final response = await http.get(Uri.parse(
        'https://finnhub.io/api/v1/search?q=$query&token=cl6fum1r01qvnck9n070cl6fum1r01qvnck9n07g'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var results = data['result'] ?? [];
      var filteredResults = results.where((result) {
        return result['type'] == 'Common Stock' &&
            !result['displaySymbol'].contains('.');
      }).toList();
      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
        });
      }
    } else {
      throw Exception('Failed to load search results');
    }
  }

  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  Widget _searchTextField() {
    return TextField(
      controller: _searchController,
      onChanged: (String s) {
        if (_debounce?.isActive ?? false) _debounce?.cancel();
        _debounce = Timer(const Duration(seconds: 1), () {
          if (s.trim().isEmpty) {
            setState(() {
              _searchResults = [];
            });
          } else {
            fetchSearchResults(s.trim());
          }
        });
      },
      autofocus: true,
      cursorColor: Colors.white,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white)),
        hintText: 'Stock Symbol, Isin, or Cusip',
        hintStyle: const TextStyle(
          color: Colors.white60,
          fontSize: 20,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults = [];
                  });
                },
                icon: const Icon(
                  Icons.clear,
                  color: Colors.white, // Change this to the color you want
                ),
              )
            : null,
      ),
    );
  }

  Widget _searchListView() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text(_searchResults[index]['description']),
            onTap: () {
              print(_searchResults[index]['displaySymbol']);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChartStock(
                    title: _searchResults[index]['displaySymbol'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  final List<String> _popularStocks = [
    'AAPL',
    'MSFT',
    'AMZN',
    'GOOGL',
    'TCEHY',
    'TSLA',
    'WMT',
    'META',
    'SSNLF',
    'JNJ'
  ]; // Add more stock symbols here

  Future<Map<String, dynamic>> fetchStock(String symbol) async {
    final response = await http.get(Uri.parse(
        'https://finnhub.io/api/v1/stock/profile2?symbol=$symbol&token=cl6fum1r01qvnck9n070cl6fum1r01qvnck9n07g'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load stock');
    }
  }

  Widget _featuredStocks() {
    return ListView.builder(
      itemCount: _popularStocks.length,
      itemBuilder: (context, index) {
        return FutureBuilder<Map<String, dynamic>>(
          future: fetchStock(_popularStocks[index]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Card(
                child: ListTile(
                  leading: SvgPicture.network(snapshot.data!['logo']),
                  title: Text(snapshot.data!['name']),
                  subtitle: Text(snapshot.data!['ticker']),
                  onTap: () {
                    print(snapshot.data!['ticker']);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChartStock(
                          title: snapshot.data!['ticker'],
                        ),
                      ),
                    );
                  },
                ),
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _searchTextField()),
      body: _searchResults.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Top 10 Stocks of all time',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: _featuredStocks()),
              ],
            )
          : _searchListView(),
    );
  }
}
