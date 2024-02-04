import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  //DateTime registrationDate = DateTime.now();
  String iban = 'No IBAN provided';
  num tax_pot = 0;
  num balance = 0;
  bool isDisabled = false;
  num disableCounter = 0;

//stores a new user in the database
  Future<void> saveUserDataToFirestore(
      String userName, String registrationDate) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? UID = user?.uid; // Get UID

    Map<String, dynamic> datatoSave = {
      'email': userName,
      'registrationDate': DateTime.now(),
      'iban': iban,
      'UID': UID,
      'tax_pot': tax_pot,
      'balance': balance,
      'isDisabled': isDisabled,
      'disableCounter': disableCounter
    };

    try {
      //DocumentReference userDocRef =
      await FirebaseFirestore.instance.collection('Users').add(datatoSave);
    } catch (e) {
      //print('Error saving user data: $e');
    }
  }

  Future<num> getUserBalance() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('UID', isEqualTo: user.uid)
          .get();
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      final balance = userData['balance'] as num;
      return balance;
    } else {
      throw Exception("User is null, cannot retrieve balance.");
    }
  }

//notwendig für die Änderung von z. B. Passwort und Iban
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
        //print('No document found for the current user.');
      }
    } else {
      //print('No user is currently logged in.');
    }
    return null;
  }

  AuthCredential getCredentials(String password) {
    AuthCredential credentials =
        EmailAuthProvider.credential(email: user!.email!, password: password);
    return credentials;
  }

//gets shown in the profile page
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
          //print('No matching document found for the current user.');
        }
      } catch (e) {
        //print('Error fetching registration date: $e');
      }
    }
    return null;
  }

/*
  Future<bool?> fetchDisabledStatus(bool isDisabled) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('UID', isEqualTo: user.uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDocument = querySnapshot.docs.first;

          bool isDisabled = userDocument.get('isDisabled');
          return isDisabled;
        }
      } catch (e) {
        print('Error fetching isDisabled: $e');
      }
    }
    return null;
  }

  Future<num?> fetchDisabledCounter(num disableDCounter) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where('UID', isEqualTo: user.uid)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot userDocument = querySnapshot.docs.first;

          num disableCounter = userDocument.get('disableCounter');
          return disableCounter;
        }
      } catch (e) {
        print('Error fetching disableCounter: $e');
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchUserStatus(String userId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('UID', isEqualTo: user!.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDocument = querySnapshot.docs.first;
        return userDocument.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error fetching user status: $e');
      return null;
    }
    return null;
  }
  */
}
