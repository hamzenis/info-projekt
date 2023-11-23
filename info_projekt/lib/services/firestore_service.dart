import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:info_projekt/auth/firebase_auth_services.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future createUserInFirestore(User user, String username) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      _firestore.collection('users').doc(user.uid).set({
        'username': username,
        'email': user.email,
        'createdOn': DateTime.now(),
      });
    }
  }

  /*Future<void> addUserToFirestore(String userId, String email) async {
    DateTime creationDate = DateTime.now();
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'createdOn': creationDate,
        // Add more user data as needed
      });
    } catch (e) {
      print('Error adding user to Firestore: $e');
    }
  }
  */

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserFromFirestore(
      String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await _firestore.collection('users').doc(userId).get();
      return userSnapshot;
    } catch (e) {
      print('Error getting user from Firestore: $e');
      rethrow;
    }
  }

  Future<void> getUserCreationDate(String userId) async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    try {
      DocumentSnapshot userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        // Accessing the 'createdOn' field from the document data
        DateTime? createdOn = userSnapshot['createdOn'];
        if (createdOn != null) {
          print('User creation date: $createdOn');
          // Use createdOn as needed
        }
      } else {
        print('User document not found');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Handle error
    }
  }
}
