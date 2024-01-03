import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //DateTime registrationDate = DateTime.now();
  String iban = 'null';

  Future<void> saveUserDataToFirestore(
      String userName, String registrationDate) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? UID = user?.uid; // Get UID

    Map<String, dynamic> datatoSave = {
      'email': userName,
      'registrationDate': DateTime.now(),
      'UID': UID
    };

    try {
      //await FirebaseFirestore.instance.collection('Users').add(datatoSave);
      DocumentReference userDocRef =
          await FirebaseFirestore.instance.collection('Users').add(datatoSave);

      // You can add additional logic or error handling here if needed
    } catch (e) {
      print('Error saving user data: $e');
      // Handle the error as per your requirement
    }
  }

  Future<num> getUserEmail() async {
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

  //Es gibt keinen Befehl alle Subcollections auf einmal zu löschen, deswegen muss man es kompliziert machen
  Future<bool> deleteUser(String? documentID, String password) async {
    User? user = FirebaseAuth.instance.currentUser;
    bool result;
    String? documentID = await getDocumentId();
    num balance = await getUserBalance();

    AuthCredential credentials =
        EmailAuthProvider.credential(email: user!.email!, password: password);
    await user.reauthenticateWithCredential(credentials);

    List<String> subcollections = [
      'stock_transaction_history',
      'portfolio',
      'balance_history'
    ];

    if (balance == 0) {
      for (String subcollection in subcollections) {
        var collectionRef = _firestore
            .collection('Users')
            .doc(documentID)
            .collection(subcollection);
        var snapshots = await collectionRef.get();
        for (var doc in snapshots.docs) {
          await doc.reference.delete();

          await _firestore.collection('Users').doc(documentID).delete();
        }
      }
      result = true;
    } else {
      result = false;
    }
    return result;
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

  Future<void> updateEmailFirestore(String newMail, String? documentID) async {
    //User? user = FirebaseAuth.instance.currentUser;
    //String? UID = user?.uid;

    FirebaseFirestore.instance
        .collection('Users')
        .doc(documentID)
        .update({"email": newMail});
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

          DateTime? registrationDate = userDocument.get('registrationDate');

          return registrationDate != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(registrationDate)
              : null;
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
