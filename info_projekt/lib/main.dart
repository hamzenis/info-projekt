import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:info_projekt/features/splashScreen.dart';
import 'package:info_projekt/pages/home_page.dart';
import 'package:info_projekt/pages/login_page.dart';
import 'package:info_projekt/pages/sign_up_page.dart'; // Import RegisterScreen



void main() {
  runApp(const MyApp());
}


class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      routes: {
        '/': (context) => SplashScreen(
          // Here, you can decide whether to show the LoginPage or HomePage based on user authentication
          child: LoginPage(),
        ),
        '/login': (context) => LoginPage(),
        '/signUp': (context) => SignUpPage(),
        '/home': (context) => HomePage(),
      },
    );
  }
}
