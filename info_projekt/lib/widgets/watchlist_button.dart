import 'package:flutter/material.dart';
import 'package:info_projekt/services/portfolio_service.dart';
import 'package:provider/provider.dart';

/// This widget is responsible for displaying the watchlist Button in the [ChartPage].
class WatchlistButton extends StatefulWidget {
  final bool isInWatchlist;
  final String title;
  final String companyName;
  final String uid;

  WatchlistButton({
    required this.isInWatchlist,
    required this.title,
    required this.companyName,
    required this.uid,
  });

  @override
  _WatchlistButtonState createState() => _WatchlistButtonState();
}

class _WatchlistButtonState extends State<WatchlistButton> {
  late bool isInWatchlist;
  final portfolioService = PortfolioService();

  @override
  void initState() {
    super.initState();
    isInWatchlist = widget.isInWatchlist;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isInWatchlist ? Icons.star : Icons.star_border,
      ),
      onPressed: () async {
        final watchlistNotifier =
            Provider.of<WatchlistNotifier>(context, listen: false);
        if (isInWatchlist) {
          await watchlistNotifier.removeFromWatchlist(widget.uid, widget.title);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stock removed from watchlist')),
          );
          setState(() {
            isInWatchlist = false;
          });
        } else {
          await watchlistNotifier.addToWatchlist(
              widget.uid, widget.companyName, widget.title);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stock added to watchlist')),
          );
          setState(() {
            isInWatchlist = true;
          });
        }
      },
    );
  }
}

/// StateNotifier for the [WatchlistPage].
class WatchlistNotifier extends ChangeNotifier {
  final PortfolioService portfolioService = PortfolioService();
  List<Map<String, dynamic>> _watchlist = [];

  List<Map<String, dynamic>> get watchlist => _watchlist;

  Future<void> loadWatchlist(String uid) async {
    _watchlist = await portfolioService.getWatchlist(uid);
    notifyListeners();
  }

  Future<void> addToWatchlist(
      String uid, String companyName, String title) async {
    await portfolioService.addToWatchlist(uid, companyName, title);
    await loadWatchlist(uid);
  }

  Future<void> removeFromWatchlist(String uid, String title) async {
    await portfolioService.removeFromWatchlist(uid, title);
    await loadWatchlist(uid);
  }
}
