import 'package:flutter/material.dart';

class Investment {
  final String symbol;
  final double quantity;
  final double price;

  Investment(
      {required this.symbol, required this.quantity, required this.price});

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      symbol: map['symbol'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'price': price,
    };
  }
}
