import '../models/ledger_row.dart';
import 'report_models.dart';

/// Per-product qty and amount, biggest amount first.
List<ProductTotals> product_totals(List<LedgerRow> rows) {
  final qty = <String, int>{};
  final amount = <String, double>{};
  for (final row in rows) {
    qty[row.sku] = (qty[row.sku] ?? 0) + row.qty.abs();
    amount[row.sku] = (amount[row.sku] ?? 0) + row.total_amount;
  }
  final skus = amount.keys.toList()
    ..sort((a, b) => amount[b]!.compareTo(amount[a]!));
  return [
    for (final sku in skus)
      ProductTotals(sku: sku, qty: qty[sku]!, amount: amount[sku]!),
  ];
}
