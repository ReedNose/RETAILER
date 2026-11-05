import '../models/ledger_row.dart';
import 'report_models.dart';

/// Totals per customer or vendor for one transaction type, biggest first.
/// Used for "By customer" (SALE rows) and "By vendor" (PURCHASE rows).
List<NameTotal> totals_by_party({
  required List<LedgerRow> rows,
  required TransactionType type,
  required SourceType source,
  required String Function(String id) name_of,
}) {
  final amounts = <String, double>{};
  for (final row in rows) {
    if (row.transaction_type != type || row.source_type != source) continue;
    amounts[row.source_id] = (amounts[row.source_id] ?? 0) + row.total_amount;
  }
  final totals = [
    for (final entry in amounts.entries)
      NameTotal(id: entry.key, name: name_of(entry.key), amount: entry.value),
  ];
  totals.sort((a, b) => b.amount.compareTo(a.amount));
  return totals;
}
