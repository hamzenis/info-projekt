// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/services/wallet_services.dart';
import 'package:info_projekt/models/transaction_history.dart';
import 'package:url_launcher/url_launcher.dart';

/// Class to create the Wallet Screen View on the TradeMate App.
/// This class works with the [WalletServices] class to deposit and withdraw money.
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

                    if (iban.isEmpty ||
                        iban == '' ||
                        iban == 'null' ||
                        iban == 'undefined') {
                      walletServices.errorDialogNoIbanFound(context);
                    } else {
                      double? withdrawAmount = await walletServices
                          .getUserWithdrawInput(context, iban);
                      if (withdrawAmount != null) {
                        await Future.delayed(const Duration(milliseconds: 500));
                        await walletServices.startWithdrawFlow(
                            context, withdrawAmount);
                        double? newBalance =
                            await walletServices.fetchBalance();
                        balance.value = newBalance;
                      }
                    }
                  }
                },
                child: const Text('Withdraw'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (kIsWeb) {
                    // If the app is running on web, start the deposit flow for web
                    double? depositAmount =
                        await walletServices.getUserInput(context);
                    if (depositAmount != null) {
                      await Future.delayed(const Duration(milliseconds: 500));
                      String? userId = FirebaseAuth.instance.currentUser!.uid;
                      String? paymentLink = await walletServices
                          .startDepositFlowWeb(depositAmount, userId);
                      if (paymentLink != null) {
                        await launch(paymentLink,
                            forceSafariVC: false, forceWebView: false);
                      }
                      setState(() {});
                    }
                  } else {
                    // If the app is running on mobile, start the deposit flow
                    double? depositAmount =
                        await walletServices.getUserInput(context);
                    if (depositAmount != null) {
                      await Future.delayed(const Duration(milliseconds: 500));
                      await walletServices.startDepositFlow(depositAmount);
                      double? newBalance = await walletServices.fetchBalance();
                      balance.value = newBalance;

                      setState(() {});
                    }
                  }
                },
                child: const Text('Deposit'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Transaction History of the User
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
                return TransactionList(userId: userDoc.id);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Transaction History of the User.
/// The data is fetched from the Firestore Database.
/// The data is sorted by date and type of transaction.
/// The data is displayed in a ListView.
/// The data is loaded in batches of 10 (Pagination)
class TransactionList extends StatefulWidget {
  final String userId;

  TransactionList({required this.userId});

  @override
  _TransactionListState createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  final _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> documentList = [];
  bool isLoading = false;
  DocumentSnapshot? lastDocument;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMore();
      }
    });
  }

  Future<void> _refresh() async {
    documentList.clear();
    lastDocument = null;
    _loadMore();
  }

  void _loadMore() {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      Query query = _firestore
          .collection('Users')
          .doc(widget.userId)
          .collection('balance_history')
          .orderBy('date', descending: true)
          .limit(30);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      query.get().then((querySnapshot) {
        documentList.addAll(querySnapshot.docs);
        isLoading = false;
        if (querySnapshot.docs.isNotEmpty) {
          lastDocument = querySnapshot.docs.last;
        }
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: documentList.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index < documentList.length) {
            final transaction =
                TransactionHistory.fromFirestore(documentList[index]);

            final color = transaction.type == TransactionType.withdrawal
                ? Colors.red
                : Colors.green;
            final amountString = transaction.type == TransactionType.withdrawal
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
          } else if (isLoading) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else {
            return null;
          }
        },
      ),
    );
  }
}
