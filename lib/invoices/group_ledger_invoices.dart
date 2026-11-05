import '../models/ledger_row.dart';
import 'ledger_invoice.dart';
import 'round_money.dart';

/// Groups ledger rows of one [type] by transaction_id, newest invoice first.
/// Rows of other types (for example spoilage) are ignored.
List<LedgerInvoice> group_ledger_invoices(
  List<LedgerRow> ledger,
  TransactionType type,
) {
  final by_id = <String, List<LedgerRow>>{};
  for (final row in ledger) {
    if (row.transaction_type != type) continue;
    by_id.putIfAbsent(row.transaction_id, () => []).add(row);
  }

  final invoices = <LedgerInvoice>[];
  for (final entry in by_id.entries) {
    final rows = List<LedgerRow>.of(entry.value)
      ..sort((a, b) => a.created_at.compareTo(b.created_at));
    final first = rows.first;
    invoices.add(LedgerInvoice(
      transaction_id: entry.key,
      date: first.date,
      type: type,
      party_id: first.source_id,
      rows: rows,
      total: round_money(rows.fold(0.0, (sum, r) => sum + r.total_amount)),
    ));
  }

  invoices.sort((a, b) {
    final by_date = b.date.compareTo(a.date);
    return by_date != 0 ? by_date : b.rows.last.created_at.compareTo(a.rows.last.created_at);
  });
  return invoices;
}
