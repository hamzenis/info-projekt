import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:info_projekt/views/splashScreen.dart';
import 'package:info_projekt/homepage.dart';
import 'package:info_projekt/views/home_page.dart';
import 'package:info_projekt/views/login_page.dart';
import 'package:info_projekt/views/sign_up_page.dart';

// Import RegisterScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // go to homepage.dart
      home: HomePageNew(),

      // debugShowCheckedModeBanner: false,
      // title: 'Flutter Firebase',
      // routes: {
      //   '/': (context) => SplashScreen(
      //         // Here, you can decide whether to show the LoginPage or HomePage based on user authentication
      //         child: LoginPage(),
      //       ),
      //   '/login': (context) => LoginPage(),
      //   '/signUp': (context) => SignUpPage(),
      //   '/home': (context) => HomePage(),
      // },
    );
  }
}
