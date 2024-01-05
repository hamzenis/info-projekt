import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  //DateTime registrationDate = DateTime.now();
  String iban = 'null';
  num tax_pot = 0;

  Future<void> saveUserDataToFirestore(
      String userName, String registrationDate) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? UID = user?.uid; // Get UID

    Map<String, dynamic> datatoSave = {
      'email': userName,
      'registrationDate': DateTime.now(),
      'UID': UID,
      'tax_pot': tax_pot
    };

    try {
      //DocumentReference userDocRef =
      await FirebaseFirestore.instance.collection('Users').add(datatoSave);
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  Future<num> getUserBalance() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('UID', isEqualTo: user?.uid)
          .get();
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final balance = userData['balance'] as num;
      return balance;
    } else {
      throw Exception("User is null, cannot retrieve balance.");
    }
  }

  //Document ID /= User ID,deswegen brauchen wir ein Snapshot, um die DocumentID zu erhalten
  //und darauf folgend Daten zu ändern oder auch zu löschen.

  Future<String?> getDocumentId() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('UID', isEqualTo: user.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDocument = querySnapshot.docs.first;
        String documentId = userDocument.id;

        return documentId;
      } else {
        print('No document found for the current user.');
      }
    } else {
      print('No user is currently logged in.');
    }
    return null;
  }

  AuthCredential getCredentials(String password) {
    AuthCredential credentials =
        EmailAuthProvider.credential(email: user!.email!, password: password);
    return credentials;
  }

  Future<String?> fetchRegistrationDate() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('UID', isEqualTo: user.uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDocument = querySnapshot.docs.first;

          Timestamp registrationDate = userDocument.get('registrationDate');

          var format = DateFormat('yyyy-MM-dd HH:mm');
          var date = registrationDate.toDate();
          return format.format(date);
        } else {
          print('No matching document found for the current user.');
          return null;
        }
      } catch (e) {
        print('Error fetching registration date: $e');
        return null;
      }
    } else {
      print('No user is currently logged in.');
      return null;
    }
  }
}
