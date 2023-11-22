import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'views/charts_view.dart';

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
        'https://financialmodelingprep.com/api/v3/search?query=$query&apikey=KKCRslaWI36ENKmv2yKfduM44Z5EDm0X'));

    if (response.statusCode == 200) {
      var results = jsonDecode(response.body);
      var filteredResults = results.where((result) {
        return !result['symbol'].contains('.');
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
                  color: Colors.white,
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
            title: Text(_searchResults[index]['name']),
            subtitle: Text(_searchResults[index]['symbol']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChartStock(
                    title: _searchResults[index]['symbol'],
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
    'TSLA',
    'WMT',
    'META',
    'JNJ'
    // Add more stock symbols here
  ];

  Future<Map<String, dynamic>> fetchStock(String symbol) async {
    final response = await http.get(Uri.parse(
        'https://financialmodelingprep.com/api/v3/profile/$symbol?apikey=KKCRslaWI36ENKmv2yKfduM44Z5EDm0X'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)[0];
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
                  leading: Image.network(snapshot.data!['image']),
                  title: Text(snapshot.data!['companyName']),
                  subtitle: Text(snapshot.data!['symbol']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChartStock(
                          title: snapshot.data!['symbol'],
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
