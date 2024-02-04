import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  //necessary for transactions
  String iban = 'No IBAN provided';
  //Verlustrechnung für Freibetrag an Steuerabzügen
  num tax_pot = 0;
  //shows the wallet balance
  num balance = 0;
  //disable status (necessary for blocking login)
  bool isDisabled = false;
  //number of failed login attempts (in a row, necessary for blocking login)
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
      //user identification number
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

//necessary for e.g. changing the IBAN and the password
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

//fetches registration date from the database and formats it (gets shown in the profile page)
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
}
