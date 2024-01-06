import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:info_projekt/services/transaction_buy_service.dart';
import 'package:info_projekt/widgets/password_input_widget.dart';
import 'package:info_projekt/common/toast.dart';

final _auth = FirebaseAuth.instance;

class BuyPopup extends StatelessWidget {
  final String stockSymbol;

  BuyPopup({required this.stockSymbol});

  @override
  Widget build(BuildContext context) {
    TextEditingController amountController = TextEditingController();

    return AlertDialog(
      title: Center(
        child: Text('Buy $stockSymbol'),
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter amount of shares you want to buy:'),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Number of Shares'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // TODO: Rewrite onPressed in a seperate function
            int enteredAmount = int.tryParse(amountController.text) ?? 0;
            if (enteredAmount == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid number'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pop();

              // Password Pop Up
              String? password = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return PasswordDialog();
                },
              );

              // Try User Password and start buy flow
              final user = _auth.currentUser;
              if (user != null) {
                if (password != null) {
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: password,
                  );
                  try {
                    await user.reauthenticateWithCredential(credential);
                    await startBuyStockFlow(enteredAmount, stockSymbol);
                  } catch (e) {
                    showToast(message: "Incorrect password");
                    return;
                  }
                }
              }
            }
          },
          child: const Text('Buy'),
        ),
      ],
    );
  }
}
