import 'package:flutter/material.dart';
import 'package:info_projekt/services/transaction_sell_service.dart';

class SellPopup extends StatelessWidget {
  final String stockSymbol;

  SellPopup({required this.stockSymbol});

  @override
  Widget build(BuildContext context) {
    TextEditingController amountController = TextEditingController();

    return AlertDialog(
      title: Center(child: Text('Sell $stockSymbol')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter number of shares to sell:'),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Number of Shares',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            int enteredAmount = int.tryParse(amountController.text) ?? 0;
            if (enteredAmount <= 0) {
              // Show error message
              return;
            }
            Navigator.of(context).pop();
            await startSellStockFlow(context, enteredAmount, stockSymbol);
          },
          child: Text('Sell'),
        ),
      ],
    );
  }
}
