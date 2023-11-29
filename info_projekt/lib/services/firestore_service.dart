import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/firestore_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  Future<void> accessCreationDate() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;

    if (currentUser != null) {
      String userId = currentUser.uid;
      await getUserCreationDate(userId);
    }
  }

  Future<void> getUserCreationDate(String userId) async {
    // Your logic to retrieve creation date from Firestore
    // ... (similar to the previous code provided)
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAuth auth = FirebaseAuth.instance;
    User? currentUser = auth.currentUser;
    String? userEmail = currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            color: Colors.blue, // Example color for the top section
            child: const Text(
              'User Profile: Work in Progress hihi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userEmail ?? 'Email not available',
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
