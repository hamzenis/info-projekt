import 'package:info_projekt/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:info_projekt/firebase_options.dart';
import 'package:info_projekt/homepage_new.dart';
import 'package:info_projekt/pages/payment_page.dart';
import 'package:info_projekt/views/splashScreen.dart';
import 'package:info_projekt/pages/home_page.dart';
import 'package:info_projekt/pages/login_page.dart';
import 'package:info_projekt/pages/sign_up_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:info_projekt/pages/verify_email_page.dart';
import 'package:info_projekt/widgets/watchlist_button.dart';
import 'package:uni_links/uni_links.dart';
import 'package:provider/provider.dart';
import 'package:info_projekt/views/wallet_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Stripe.publishableKey =
      "pk_test_51OCfrgEFCGzXnEeOd1oT0r7x9bEhxiXxXv6VJyf6LWO1E8ZMtwx7cWjVdlidFPnRo4aG3xF5bTpsk5iOPe3toFmZ00MXrBqrOa";
  Stripe.merchantIdentifier = 'MerchantIdentifier';

  runApp(
    ChangeNotifierProvider(
      create: (context) => WatchlistNotifier(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      routes: {
        '/': (context) => SplashScreen(
              child: const LoginPage(),
            ),
        '/login': (context) => const LoginPage(),
        '/homePageNew': (context) => HomePageNew(),
        '/signUp': (context) => const SignUpPage(),
        '/verifyEmail': (context) => VerifyEmailPage(),
        '/profile': (context) => ProfilePage(), // Added ProfilePage route
        '/home': (context) =>
            HomePage(), // Old Homepage, not deleted yet because of hotreload route
        '/wallet': (context) => const WalletScreen(),
        '/payment': (context) => FutureBuilder<String?>(
              future: getInitialLink(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  final currentUri = Uri.parse(snapshot.data ?? '');
                  final clientSecret =
                      currentUri.queryParameters['client_secret'] ?? '';
                  return PaymentPage(clientSecret: clientSecret);
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
        '/payment-success': (context) => const WalletScreen(),
        '/payment-cancel': (context) => const WalletScreen(),
      },
    );
  }
}
