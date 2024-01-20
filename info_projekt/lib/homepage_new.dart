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

class HomePageNew extends StatefulWidget {
  HomePageNew({Key? key}) : super(key: key);

  static final GlobalKey<PortfolioOverviewState> portfolioOverviewKey =
      GlobalKey<PortfolioOverviewState>();

  @override
  _HomePageNewState createState() => _HomePageNewState();
}

class _HomePageNewState extends State<HomePageNew> {
  final PortfolioService portfolioService = PortfolioService();
  final portfolioValueNotifierKey = GlobalKey();
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PortfolioValueNotifier(uid),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TradeMate'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              PortfolioOverview(
                uid: uid,
              ),
              TabBarClass(
                tabs: [
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
                            ValueNotifier(snapshot.data ?? []), uid);
                      }
                    },
                  ),
                  Container(child: WatchlistPage()),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: MenuButton(
          distance: 112.0,
          children: [
            Icon(Icons.search),
            Icon(Icons.newspaper),
            Icon(Icons.person),
            Icon(Icons.wallet),
          ],
          pageBuilders: [
            (context) => SearchPage(),
            (context) => NewsPage(),
            (context) => ProfilePage(),
            (context) => WalletScreen(),
          ],
        ),
      ),
    );
  }
}
