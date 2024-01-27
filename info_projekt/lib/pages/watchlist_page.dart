import 'package:flutter/material.dart';
import 'package:info_projekt/views/charts_view.dart';
import 'package:info_projekt/widgets/watchlist_button.dart';
import 'package:provider/provider.dart';

/// This Class is responsible for displaying the watchlist of the user.
class WatchlistPage extends StatefulWidget {
  final String uid;

  WatchlistPage({required this.uid});

  @override
  _WatchlistPageState createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      await Provider.of<WatchlistNotifier>(context, listen: false)
          .loadWatchlist(widget.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WatchlistNotifier>(
        builder: (context, watchlistNotifier, child) {
          var watchlist = watchlistNotifier.watchlist;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: watchlist.isEmpty
                ? const Text(
                    'Watchlist items will appear here when available.',
                    style: TextStyle(color: Colors.grey),
                  )
                : ListView.builder(
                    itemCount: watchlist.length,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChartStock(
                                title: watchlist[index]['symbol'],
                              ),
                            ),
                          );
                        },
                        child: ListTile(
                          title: Text(watchlist[index]['name']),
                          subtitle: Text(watchlist[index]['symbol']),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
