import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/widgets/sell_popup.dart';

class OwnedStocksPage extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('Users')
          .where('UID', isEqualTo: _auth.currentUser?.uid)
          .get(),
      builder:
          (BuildContext context, AsyncSnapshot<QuerySnapshot> userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Owned Stocks'),
            ),
            body: const Text('No user data'),
          );
        }
        final userDoc = userSnapshot.data!.docs.first;
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Users')
              .doc(userDoc.id)
              .collection('stock_transaction_history')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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
                  body: buildListView(transactions), //HERE
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
                body: Center(
                  child: Text("No data"),
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
          },
        );
      },
    );
  }
}

ListView buildListView(List<QueryDocumentSnapshot> transactions) {
  return ListView.builder(
    itemCount: transactions.length,
    itemBuilder: (context, index) {
      final transaction = transactions[index];
      print(transactions.length);
      return Container(
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListTile(
          title: Text(transaction['stock_symbol']),
          subtitle: Text(
              ' Amount: ${transaction['amount']}\n Price: \$${transaction['price']}\n Date: ${transaction['date'].toDate().toString().substring(0, 16)}\n Type: ${transaction['type'] ? 'Buy' : 'Sell'}'),
          trailing: IconButton(
            icon: const Icon(Icons.sell),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => SellPopup(
                  stockSymbol: transaction['stock_symbol'],
                  documentId: transaction
                      .id, // Assuming transaction is a DocumentSnapshot
                ),
              );
            },
          ),
        ),
      );
    },
  );
}
