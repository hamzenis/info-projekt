import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:info_projekt/services/search_service.dart';
import 'charts_view.dart';

/// Class to create the Search Page View on the TradeMate App.
/// This class works with the [SearchService] class to search for stocks.
class SearchPage extends StatefulWidget {
  final String title;

  const SearchPage({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SearchPage createState() => _SearchPage();
}

class _SearchPage extends State<SearchPage> {
  List<dynamic> _searchResults = [];
  late final SearchService _searchService;

  @override
  void initState() {
    super.initState();
    _searchService = SearchService(onSearchResults: updateSearchResults);
  }

  void updateSearchResults(List<dynamic> results) {
    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  Widget _searchTextField() {
    return TextField(
      controller: _searchController,
      onChanged: (String s) {
        if (_debounce?.isActive ?? false) _debounce?.cancel();
        // 1 second delay before searching -> less API calls
        _debounce = Timer(const Duration(seconds: 1), () {
          if (s.trim().isEmpty) {
            setState(() {
              _searchResults = [];
            });
          } else {
            // If the search query is not empty, fetch the search results
            _searchService.fetchSearchResults(s.trim());
          }
        });
      },
      autofocus: true,
      cursorColor: Colors.black,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 20,
      ),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent)),
        hintText: 'Stock Symbol, Isin, or Cusip',
        hintStyle: const TextStyle(
          color: Colors.black54,
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
                  color: Colors.black,
                ),
              )
            : null,
      ),
    );
  }

  /// Function to create the search results list view.
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
                // go to charts_view.dart when clicking on a stock
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

  /// List of popular stocks to display on the search page.
  final List<String> _popularStocks = [
    'AAPL',
    'MSFT',
    'AMZN',
    'GOOGL',
    'TSLA',
    'KO',
    'WMT',
    'META',
    'JNJ',
    'NFLX'
    // Add more stock symbols here
  ];

  /// Function to create the featured stocks list view.
  Widget _featuredStocks() {
    return ListView.builder(
      itemCount: _popularStocks.length,
      itemBuilder: (context, index) {
        // Fetch the stock data for each stock symbol in _popularStocks list
        return FutureBuilder<Map<String, dynamic>>(
          future: _searchService.fetchStock(_popularStocks[index]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Card(
                child: ListTile(
                  // Cached Network Image is used to cache the stock logo
                  leading: CachedNetworkImage(
                    imageUrl: snapshot.data!['image'],
                    placeholder: (context, url) => CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                  title: Text(snapshot.data!['companyName']),
                  subtitle: Text(snapshot.data!['symbol']),
                  onTap: () {
                    Navigator.push(
                      context,
                      // go to charts_view.dart when clicking on a stock
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
    final searchService = SearchService(onSearchResults: updateSearchResults);

    return Scaffold(
      appBar: AppBar(title: _searchTextField()),

      /// If the search results are empty, display the featured stocks list view.
      /// If the search results are not empty, display the search results list view.
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
