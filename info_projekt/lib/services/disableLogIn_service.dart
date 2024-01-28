import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/services/firestore_service.dart';
//import 'package:flutter/material.dart';
//import 'package:intl/intl.dart';

class DisableLogIn {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  User? user = FirebaseAuth.instance.currentUser;

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

  /* Future<bool?> fetchDisabledStatus(bool isDisabled) async {
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

  */

  Future<num?> fetchDisabledCounter(String userId) async {
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

  Future<void> updateIsDisabled(String userId, bool isDisabled) async {
    String? docId = await _firestoreService.getDocumentId();
    await _firestore.collection('Users').doc(docId).update({
      'isDisabled': isDisabled,
    });
  }

  Future<void> updateDisableCounter(String userId, num disableCounter) async {
    String? docId = await _firestoreService.getDocumentId();
    await _firestore.collection('Users').doc(docId).update({
      'disableCounter': disableCounter,
    });
  }
}
