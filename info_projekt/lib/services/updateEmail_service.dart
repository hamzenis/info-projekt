import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//updates the email in the database when email is changed (user profile)
class UpdateEmail {
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> updateEmailFirestore(String newMail, String? documentID) async {
    FirebaseFirestore.instance
        .collection('Users')
        .doc(documentID)
        .update({"email": newMail});
  }
}
