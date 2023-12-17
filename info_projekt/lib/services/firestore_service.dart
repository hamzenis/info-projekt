import 'package:info_projekt/pages/sign_up_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/services/firebase_auth_services.dart';
import 'package:info_projekt/common/toast.dart';
import 'package:info_projekt/pages/login_page.dart';
import 'package:info_projekt/widgets/form_container_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUserDataToFirestore(
      String userName, String registrationDate) async {
    Map<String, String> datatoSave = {
      'email': userName,
      'registrationDate': registrationDate,
    };

    //Initialisierung
    double price = 0;
    String orderDate = ' ';
    String name = ' ';
    String symbol = ' ';
    bool buy = false;
    double sellingPrice = 0;
    int quantity = 0;
    double totalCost = 0;
    double transactionFee = 0;

    Map<String, dynamic> transactionData = {
      'price': price,
      'order_date': orderDate,
      'name': name,
      'symbol': symbol,
      'buy': buy,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'total_cost': totalCost,
      'transaction_fee': transactionFee,
    };

    double amount = 0;
    Timestamp date = Timestamp.now();
    String description = ' ';
    bool withdraw = false;

    Map<String, dynamic> balanceData = {
      'amount': 0,
      'date': Timestamp.now(),
      'description': ' ',
      'withdraw': false,
    };

    try {
      //await FirebaseFirestore.instance.collection('Users').add(datatoSave);
      DocumentReference userDocRef =
          await FirebaseFirestore.instance.collection('Users').add(datatoSave);

      CollectionReference transactionHistoryRef =
          userDocRef.collection('transaction_history');

      await transactionHistoryRef.add(transactionData);

      CollectionReference balanceHistoryRef =
          userDocRef.collection('balance_history');
      await balanceHistoryRef.add(balanceData);

      // You can add additional logic or error handling here if needed
    } catch (e) {
      print('Error saving user data: $e');
      // Handle the error as per your requirement
    }
  }

  Future<String> fetchRegistrationDate(String userId) async {
    String registrationDate = '';
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('Users').doc(userId).get();

      if (documentSnapshot.exists) {
        var data = documentSnapshot.data() as Map<String, dynamic>?;
        registrationDate = data?['registrationDate'] as String? ??
            ''; // Fallback to empty string if not found
      }
    } catch (e) {
      print('Error fetching registration date: $e');
    }
    return registrationDate;
  }
}
