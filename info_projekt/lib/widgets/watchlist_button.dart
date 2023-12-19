import 'package:flutter/material.dart';
import 'package:info_projekt/services/portfolio_service.dart';

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
        if (isInWatchlist) {
          try {
            await portfolioService.removeFromWatchlist(
                widget.uid, widget.title);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Stock removed from watchlist')),
            );
            setState(() {
              isInWatchlist = false;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        } else {
          try {
            await portfolioService.addToWatchlist(
              widget.uid,
              widget.companyName,
              widget.title,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Stock added to watchlist')),
            );
            setState(() {
              isInWatchlist = true;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        }
      },
    );
  }
}
