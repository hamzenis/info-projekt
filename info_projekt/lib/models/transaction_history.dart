import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/views/wallet_screen.dart';

/// This class create a transaction history object.
/// [amount] is the amount that the user deposited or withdrew.
/// [date] is the time when the transaction was made.
/// [description] display the type of transaction.
/// [type] is the type of the transaction. It can be either withdrawal or deposit
/// the [type] is used to display the correct amount color in the [WalletScreen].
class TransactionHistory {
  final double amount;
  final DateTime date;
  final String description;
  final TransactionType type;

  TransactionHistory({
    required this.amount,
    required this.date,
    required this.description,
    required this.type,
  });

  /// Method creates a transaction history object from a firestore document.
  /// [doc] is the firestore snapshot of the transaction history.
  /// This kind of function enables to create a transaction history from
  /// the firestore database in the [WalletScreen].
  /// Returns a transaction history object to display it in the [WalletScreen].
  factory TransactionHistory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final amount = (data['amount'] as num).toDouble();
    final date = (data['date'] as Timestamp).toDate();
    final description = data['description'] as String;
    final type = data['withdraw'] == true
        ? TransactionType.withdrawal
        : TransactionType.deposit;

    return TransactionHistory(
      amount: amount,
      date: date,
      description: description,
      type: type,
    );
  }
}

enum TransactionType { deposit, withdrawal }
