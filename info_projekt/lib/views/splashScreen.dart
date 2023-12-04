import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/firebase_options.dart';
import 'package:info_projekt/pages/home_page.dart';
import 'package:info_projekt/pages/login_page.dart';
import 'package:info_projekt/services/uri_service.dart';

// TODO Comment this class and the methods
class SplashScreen extends StatelessWidget {
  final Widget child;
  final UriService uriService;

  SplashScreen({Key? key, required this.child})
      : uriService = getUriService(),
        super(key: key);

  @override
  @override
  Widget build(BuildContext context) {
    final currentUri = uriService.currentUri;
    final currentRoute = currentUri.path;

    return FutureBuilder<FirebaseApp>(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SomethingWentWrong();
        }

        if (snapshot.connectionState == ConnectionState.done) {
          if (currentRoute == '/payment') {
            return child;
          }

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasData) {
                  return HomePage();
                } else {
                  return LoginPage();
                }
              }
            },
          );
        }

        return CircularProgressIndicator();
      },
    );
  }
}

class SomethingWentWrong extends StatelessWidget {
  const SomethingWentWrong({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Something went wrong!'),
      ),
    );
  }
}
