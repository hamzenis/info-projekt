// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/services/wallet_services.dart';
import 'package:info_projekt/models/transaction_history.dart';

/// Class to create the Wallet Screen View on the TradeMate App.
/// This class works with the [WalletServices] class to deposit and withdraw money.
/// The Service functionality is in the folder info_projekt/services/wallet_services.dart.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  WalletServices walletServices = WalletServices();
  // Balance is choose to be a ValueNotifier to be able to update ONLY the balance
  ValueNotifier<double?> balance = ValueNotifier(null);

  /// Function to refresh the balance of the user.
  @override
  void initState() {
    super.initState();
    fetchInitialBalance();
  }

  /// Function to fetch the initial balance of the user.
  Future<void> fetchInitialBalance() async {
    double? initialBalance = await walletServices.fetchBalance();
    balance.value = initialBalance;
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
          // ValueListenableBuilder is used to update the balance when the user deposits or withdraws money.
          ValueListenableBuilder<double?>(
            valueListenable: balance,
            builder: (BuildContext context, double? value, Widget? child) {
              if (value == null) {
                return const CircularProgressIndicator();
              } else {
                return Text(
                  'Balance: \$${value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24.0),
                );
              }
            },
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              /// The Functionality of the buttons is in the [WalletServices] class.
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
                      double? newBalance = await walletServices.fetchBalance();
                      balance.value = newBalance;
                    }
                  }
                },
                child: const Text('Withdraw'),
              ),
              ElevatedButton(
                /// The Functionality of the buttons is in the [WalletServices] class.
                onPressed: () async {
                  double? depositAmount =
                      await walletServices.getUserInput(context);
                  if (depositAmount != null) {
                    await Future.delayed(const Duration(milliseconds: 500));
                    await walletServices.startDepositFlow(depositAmount);
                    double? newBalance = await walletServices.fetchBalance();
                    balance.value = newBalance;
                  }
                },
                child: const Text('Deposit'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          /// Transaction History of the User.
          /// The data is fetched from the Firestore Database.
          /// The data is sorted by date and type of transaction.
          /// The data is displayed in a ListView.
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
                    transactions.sort((a, b) {
                      var compareDate = b.date.compareTo(a.date);
                      if (compareDate != 0) return compareDate;
                      if (a.type == TransactionType.withdrawal) return -1;
                      if (b.type == TransactionType.withdrawal) return 1;
                      return 0;
                    });
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (BuildContext context, int index) {
                        final transaction = transactions[index];

                        final color = transaction.type ==
                                TransactionType
                                    .withdrawal // Color is changed depending on the type of transaction.
                            ? Colors.red
                            : Colors.green;
                        final amountString = transaction.type ==
                                TransactionType
                                    .withdrawal // A '-' is added to the amount if the transaction is a withdrawal.
                            ? '-\$${transaction.amount.toStringAsFixed(2)}'
                            : '\$${transaction.amount.toStringAsFixed(2)}';

                        return ListTile(
                          title: Text(transaction.description),
                          subtitle: Text(transaction.date.toString()),
                          trailing: Text(
                            amountString,
                            style: TextStyle(color: color),
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
