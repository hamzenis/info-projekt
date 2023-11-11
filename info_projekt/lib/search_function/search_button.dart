import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

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

  Widget _searchTextField() {
    return TextField(
      controller: _searchController,
      onChanged: (String s) {
        if (s.trim().isEmpty) {
          setState(() {
            _searchResults = [];
          });
        } else {
          fetchSearchResults(s.trim());
        }
      },
      autofocus: true,
      cursorColor: Colors.white,
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        enabledBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        hintText: 'Stock Symbol, Isin, or Cusip',
        hintStyle: TextStyle(
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
                icon: Icon(
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
            },
          ),
        );
      },
    );
  }

  List<String> _popularStocks = ['AAPL', 'AMZN']; // Add more stock symbols here

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
                  },
                ),
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return Center(child: CircularProgressIndicator());
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Popular Stocks',
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
