import '../models/ledger_row.dart';
import 'invoice_models.dart';
import 'round_money.dart';

/// Merges the day's sale rows into one line per product, sorted by name.
/// The line total is the exact sum of the sales, so discounts on single
/// batches are never lost; the unit price shown is the average.
List<InvoiceLine> build_invoice_lines({
  required List<LedgerRow> rows,
  required String Function(String sku) product_name_of,
}) {
  final qty_by_sku = <String, int>{};
  final amount_by_sku = <String, double>{};
  for (final row in rows) {
    qty_by_sku[row.sku] = (qty_by_sku[row.sku] ?? 0) + row.qty.abs();
    amount_by_sku[row.sku] = (amount_by_sku[row.sku] ?? 0) + row.total_amount;
  }

  final lines = <InvoiceLine>[];
  for (final sku in qty_by_sku.keys) {
    final qty = qty_by_sku[sku]!;
    final line_total = round_money(amount_by_sku[sku]!);
    lines.add(InvoiceLine(
      sku: sku,
      product_name: product_name_of(sku),
      qty: qty,
      unit_price: qty == 0 ? 0 : round_money(line_total / qty),
      line_total: line_total,
    ));
  }
  lines.sort((a, b) => a.product_name.compareTo(b.product_name));
  return lines;
}
