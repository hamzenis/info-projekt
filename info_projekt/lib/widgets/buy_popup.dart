import 'package:flutter/material.dart';
import 'package:info_projekt/services/transaction_buy_service.dart';

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
            int enteredAmount = int.tryParse(amountController.text) ?? 0;
            print(
                'User entered: $enteredAmount'); // TODO: Remove this DEBUG line
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
              print("Starting Buy Flow"); // TODO: Remove this DEBUG line
              await startBuyStockFlow(context, enteredAmount, stockSymbol);
            }
          },
          child: const Text('Buy'),
        ),
      ],
    );
  }
}
