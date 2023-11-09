import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Widget _searchTextField() {
    return TextField(
      onChanged: (String s) {
        fetchSearchResults(s.trim());
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
        hintText: 'Search Stocks',
        hintStyle: TextStyle(
          color: Colors.white60,
          fontSize: 20,
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: _searchTextField()), body: _searchListView());
  }
}
