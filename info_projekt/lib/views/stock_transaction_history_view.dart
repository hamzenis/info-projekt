import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:info_projekt/widgets/sell_popup.dart';

// TODO: Rewrite this page and make it stable
class OwnedStocksPage extends StatefulWidget {
  @override
  _OwnedStocksPageState createState() => _OwnedStocksPageState();
}

class _OwnedStocksPageState extends State<OwnedStocksPage>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              title: Text('Stock Transaction History'),
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
                    title: Text('Stock Transaction History'),
                  ),
                  body: Center(child: Text("Error: ${snapshot.error}")),
                );
              }
              if (snapshot.hasData) {
                final transactions = snapshot.data?.docs ?? [];
                return Scaffold(
                  appBar: AppBar(
                    title: Text('Stock Transaction History'),
                  ),
                  body: buildListView(transactions), //HERE
                );
              } else {
                return Scaffold(
                  appBar: AppBar(
                    title: Text('Stock Transaction History'),
                  ),
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            } else if (snapshot.connectionState == ConnectionState.none) {
              return Scaffold(
                appBar: AppBar(
                  title: Text('Stock Transaction History'),
                ),
                body: Center(
                  child: Text("No data"),
                ),
              );
            } else {
              return Scaffold(
                appBar: AppBar(
                  title: Text('Stock Transaction History'),
                ),
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        );
      },
    );
  }

  ListView buildListView(List<QueryDocumentSnapshot> transactions) {
    // Sort transactions by date in descending order
    transactions.sort((a, b) => b['date'].compareTo(a['date']));

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];

        String roundedPrice = double.parse(transaction['price'].toString())
            .toStringAsFixed(2); // Round the price to 2 decimal places

        Color tileColor = transaction['type'] ? Colors.green : Colors.red;

        bool isLastTransaction = index == 0;

        return isLastTransaction
            ? AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: tileColor,
                      border: Border.all(
                        color: Color.fromARGB(255, 0, 0, 255)
                            .withOpacity(_controller.value),
                        width: 3.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      title: Text(transaction['symbol']),
                      subtitle: Text(
                          ' Amount: ${transaction['amount']}\n Price: \$$roundedPrice\n Date: ${transaction['date'].toDate().toString().substring(0, 16)}\n Type: ${transaction['type'] ? 'Buy' : 'Sell'}'),
                    ),
                  );
                },
              )
            : Container(
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: tileColor,
                  border: Border.all(color: Colors.black, width: 0.5),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  title: Text(transaction['symbol']),
                  subtitle: Text(
                      ' Amount: ${transaction['amount']}\n Price: \$$roundedPrice\n Date: ${transaction['date'].toDate().toString().substring(0, 16)}\n Type: ${transaction['type'] ? 'Buy' : 'Sell'}'),
                ),
              );
      },
    );
  }
}
