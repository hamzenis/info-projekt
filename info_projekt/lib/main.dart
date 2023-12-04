import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:info_projekt/views/splashScreen.dart';
import 'package:info_projekt/views/home_page.dart';
import 'package:info_projekt/pages/login_page.dart';
import 'package:info_projekt/pages/sign_up_page.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:info_projekt/pages/verify_email_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Stripe.publishableKey =
      "pk_test_51OCfrgEFCGzXnEeOd1oT0r7x9bEhxiXxXv6VJyf6LWO1E8ZMtwx7cWjVdlidFPnRo4aG3xF5bTpsk5iOPe3toFmZ00MXrBqrOa";
  Stripe.merchantIdentifier = 'MerchantIdentifier';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // go to homepage.dart
      // home: HomePageNew(),

      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      routes: {
        '/': (context) => const SplashScreen(
              // Here, you can decide whether to show the LoginPage or HomePage based on user authentication
              child: LoginPage(),
            ),
        '/login': (context) => const LoginPage(),
        '/signUp': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/verifyEmail': (context) => VerifyEmailPage(),
      },
    );
  }
}
