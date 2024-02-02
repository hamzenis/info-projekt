import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/pages/investment_page.dart';
import 'package:info_projekt/pages/portfolio_overview.dart';
import 'package:info_projekt/pages/profile_page.dart';
import 'package:info_projekt/pages/watchlist_page.dart';
import 'package:info_projekt/provider/portfolio.dart';
import 'package:info_projekt/views/wallet_screen.dart';
import 'package:provider/provider.dart';
import 'views/search_view.dart';
import 'views/newspage.dart';
import 'services/portfolio_service.dart';
import 'widgets/menubutton.dart';
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
          floatingActionButton: MenuButton(
            distance: 112.0,
            pageBuilders: [
              (context) => const SearchPage(),
              (context) => const NewsPage(),
              (context) => ProfilePage(),
              (context) => const WalletScreen(),
            ],
            children: const [
              Icon(Icons.search),
              Icon(Icons.newspaper),
              Icon(Icons.person),
              Icon(Icons.wallet),
            ],
          ),
        ),
      ),
    );
  }
}
