import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:info_projekt/views/wallet_screen.dart';

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

  factory TransactionHistory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final amount = (data['amount'] as num).toDouble();
    final date = (data['date'] as Timestamp).toDate();
    final description = data['description'] as String;
    final type = data['type'] == 'withdrawal'
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
