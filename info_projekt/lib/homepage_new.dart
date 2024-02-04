import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/pages/investment_page.dart';
import 'package:info_projekt/pages/portfolio_overview.dart';
import 'package:info_projekt/pages/profile_page.dart';
import 'package:info_projekt/pages/watchlist_page.dart';
import 'package:info_projekt/provider/portfolio.dart';
import 'package:info_projekt/views/wallet_screen.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'views/search_view.dart';
import 'views/newspage.dart';
import 'services/portfolio_service.dart';
import 'widgets/tab_bar.dart';

/// The home page of the app aka. the portfolio page of the user.<br />
/// It contains the [PortfolioOverview] widget and a [TabBarClass] widget.<br />
/// The [TabBarClass] widget contains the [InvestmentPage] and the [WatchlistPage].<br />
/// It also contains the [MenuButton] widget.<br />
class HomePageNew extends StatefulWidget {
  HomePageNew({Key? key}) : super(key: key);

  static final GlobalKey<PortfolioOverviewState> portfolioOverviewKey =
      GlobalKey<PortfolioOverviewState>();

  final ValueNotifier<bool> refreshNotifier = ValueNotifier(false);

  @override
  HomePageNewState createState() => HomePageNewState();
}

class HomePageNewState extends State<HomePageNew> {
  final PortfolioService portfolioService = PortfolioService();
  final portfolioValueNotifierKey = GlobalKey();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async => false,
      child: ChangeNotifierProvider(
        create: (context) => PortfolioValueNotifier(uid),
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('TradeMate'),
            backgroundColor: const Color.fromRGBO(126, 192, 238, 1),
          ),
          body: Column(
            children: [
              PortfolioOverview(widget.refreshNotifier, uid,
                  key: portfolioValueNotifierKey),
              Expanded(
                child: TabBarClass(
                  tabs: const [
                    Tab(text: 'Investments'),
                    Tab(text: 'Watchlist'),
                  ],
                  tabBarViews: [
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: portfolioService.getIndividualInvestmentsStream(
                          uid: uid),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return InvestmentPage(
                              ValueNotifier(snapshot.data ?? []),
                              uid,
                              widget.refreshNotifier);
                        }
                      },
                    ),
                    WatchlistPage(uid: uid),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: SpeedDial(
            animatedIcon: AnimatedIcons.menu_close,
            animatedIconTheme: const IconThemeData(size: 22.0),
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.search),
                label: 'Shares',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage()),
                ),
              ),
              SpeedDialChild(
                child: const Icon(Icons.newspaper),
                label: 'News',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsPage()),
                ),
              ),
              SpeedDialChild(
                child: const Icon(Icons.person),
                label: 'Profile',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                ),
              ),
              SpeedDialChild(
                child: const Icon(Icons.wallet),
                label: 'Wallet',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WalletScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
