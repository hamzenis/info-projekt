import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addUserToFirestore(String userId, String email) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        // Add more user data as needed
      });
    } catch (e) {
      print('Error adding user to Firestore: $e');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserFromFirestore(String userId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await _firestore.collection('users').doc(userId).get();
      return userSnapshot;
    } catch (e) {
      print('Error getting user from Firestore: $e');
      throw e;
    }
  }
}
