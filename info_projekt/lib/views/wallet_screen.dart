// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/services/wallet_services.dart';
import 'package:info_projekt/models/transaction_history.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  WalletServices walletServices = WalletServices();
  double? balance;

  Stream<double> getBalanceStream() async* {
    while (true) {
      yield await walletServices.fetchBalance();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16.0),
          StreamBuilder<double>(
            stream: getBalanceStream(),
            builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData) {
                return const Text('No data');
              }
              var balance = snapshot.data;
              return Text(
                'Balance: \$${balance?.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24.0),
              );
            },
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final user = _auth.currentUser;
                  if (user != null) {
                    final querySnapshot = await _firestore
                        .collection('Users')
                        .where('UID', isEqualTo: user.uid)
                        .get();
                    final userDoc = querySnapshot.docs.first;
                    final userData = userDoc.data();
                    final iban = userData['iban'] as String;

                    double? withdrawAmount = await walletServices
                        .getUserWithdrawInput(context, iban);
                    if (withdrawAmount != null) {
                      await Future.delayed(const Duration(milliseconds: 500));
                      await walletServices.startWithdrawFlow(
                          context, withdrawAmount);
                      balance = await walletServices.fetchBalance();
                    }
                  }
                },
                child: const Text('Withdraw'),
              ),
              ElevatedButton(
                onPressed: () async {
                  double? depositAmount =
                      await walletServices.getUserInput(context);
                  if (depositAmount != null) {
                    await Future.delayed(const Duration(milliseconds: 500));
                    await walletServices.startDepositFlow(depositAmount);
                    balance = await walletServices.fetchBalance();
                  }
                },
                child: const Text('Deposit'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: _firestore
                  .collection('Users')
                  .where('UID', isEqualTo: _auth.currentUser?.uid)
                  .get(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                  return const Text('No user data');
                }
                final userDoc = userSnapshot.data!.docs.first;
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('Users')
                      .doc(userDoc.id)
                      .collection('balance_history')
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData) {
                      return const Text('No transactions');
                    }
                    final transactions = snapshot.data!.docs
                        .map((doc) => TransactionHistory.fromFirestore(doc))
                        .toList();
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (BuildContext context, int index) {
                        var sortedTransactions = transactions
                          ..sort((a, b) {
                            var compareDate = b.date.compareTo(a.date);
                            if (compareDate != 0) return compareDate;
                            if (a.type == TransactionType.withdrawal) return -1;
                            if (b.type == TransactionType.withdrawal) return 1;
                            return 0;
                          });
                        return ListTile(
                          title: Text(sortedTransactions[index].description),
                          subtitle:
                              Text(sortedTransactions[index].date.toString()),
                          trailing: Text(
                            '\$${sortedTransactions[index].amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: sortedTransactions[index].type ==
                                      TransactionType.withdrawal
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum TransactionType { deposit, withdrawal }
