import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //DateTime registrationDate = DateTime.now();
  num balance = 0;
  String iban = 'null';
  num tax_pot = 0;

  Future<void> saveUserDataToFirestore(
      String userName, String registrationDate) async {
    User? user = FirebaseAuth.instance.currentUser;
    String? UID = user?.uid; // Get UID

    Map<String, dynamic> datatoSave = {
      'email': userName,
      'registrationDate': DateTime.now(),
      'iban': iban,
      'balance': balance,
      'taxpot': tax_pot,
      'UID': UID
    };

    Map<String, dynamic> stockTransactionHistoryData = {};
    Map<String, dynamic> balanceData = {};
    Map<String, dynamic> portfolioData = {};

    try {
      //await FirebaseFirestore.instance.collection('Users').add(datatoSave);
      DocumentReference userDocRef =
          await FirebaseFirestore.instance.collection('Users').add(datatoSave);

      CollectionReference stockTransactionHistoryRef =
          userDocRef.collection('stock_transaction_history');
      await stockTransactionHistoryRef.add(stockTransactionHistoryData);

      CollectionReference balanceHistoryRef =
          userDocRef.collection('balance_history');
      await balanceHistoryRef.add(balanceData);

      CollectionReference portfolioRef = userDocRef.collection('portfolio');
      await portfolioRef.add(portfolioData);

      // You can add additional logic or error handling here if needed
    } catch (e) {
      print('Error saving user data: $e');
      // Handle the error as per your requirement
    }
  }

  //Es gibt keinen Befehl alle Subcollections auf einmal zu löschen, deswegen muss man es kompliziert machen
  Future<void> deleteUser(String? documentID) async {
    String? documentID = await getDocumentId();

    List<String> subcollections = [
      'stock_transaction_history',
      'portfolio',
      'balance_history'
    ];

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
