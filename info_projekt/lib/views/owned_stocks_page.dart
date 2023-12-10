import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnedStocksPage extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Users')
          .doc(_auth.currentUser?.uid)
          .collection('transaction_history')
          .where('owned', isEqualTo: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Owned Stocks'),
              ),
              body: Center(child: Text("Error: ${snapshot.error}")),
            );
          }

          if (snapshot.hasData) {
            final transactions = snapshot.data?.docs ?? [];
            return Scaffold(
              appBar: AppBar(
                title: Text('Owned Stocks'),
              ),
              body: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return ListTile(
                    title: Text(transaction['stock_symbol']),
                    subtitle: Text('Amount: ${transaction['amount']}'),
                  );
                },
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                title: Text('Owned Stocks'),
              ),
              body: Center(child: CircularProgressIndicator()),
            );
          }
        } else if (snapshot.connectionState == ConnectionState.none) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Owned Stocks'),
            ),
            body: Center(child: Text("No data")),
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Owned Stocks'),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
