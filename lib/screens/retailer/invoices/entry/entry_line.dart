import 'package:flutter/material.dart';

import '../../../../core/input_parsing.dart';
import '../../../../invoices/round_money.dart';

/// One editable row of an invoice being entered.
class EntryLine {
  EntryLine({
    required this.sku,
    this.batch_id,
    int qty = 1,
    required double price,
  })  : qty_controller = TextEditingController(text: '$qty'),
        price_controller = TextEditingController(text: price.toStringAsFixed(2));

  final Key key = UniqueKey();
  String sku;
  String? batch_id; // sales only
  final TextEditingController qty_controller;
  final TextEditingController price_controller;

  int get qty => int.tryParse(qty_controller.text.trim()) ?? 0;
  double get price => parse_money(price_controller.text) ?? 0;
  double get amount => round_money(qty * price);

  void dispose() {
    qty_controller.dispose();
    price_controller.dispose();
  }
}
