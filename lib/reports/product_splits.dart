import '../models/ledger_row.dart';
import 'report_models.dart';
import 'sum_amounts.dart';

/// Sales, purchases and spoilage for each product, in sku order.
List<ProductSplit> product_splits(List<LedgerRow> rows) {
  final skus = <String>{for (final row in rows) row.sku}.toList()..sort();
  final splits = <ProductSplit>[];
  for (final sku in skus) {
    final mine = rows.where((row) => row.sku == sku).toList();
    splits.add(ProductSplit(
      sku: sku,
      sales: sum_amounts(mine, TransactionType.sale),
      purchases: sum_amounts(mine, TransactionType.purchase),
      spoilage: sum_amounts(mine, TransactionType.spoilage),
    ));
  }
  return splits;
}
