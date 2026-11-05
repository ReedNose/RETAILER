import '../models/ledger_row.dart';

/// One invoice = every ledger row that shares a transaction_id.
/// Used for purchase invoices (vendor) and sales invoices (customer).
class LedgerInvoice {
  const LedgerInvoice({
    required this.transaction_id,
    required this.date,
    required this.type,
    required this.party_id,
    required this.rows,
    required this.total,
  });

  final String transaction_id; // the invoice number
  final DateTime date;
  final TransactionType type; // purchase or sale
  final String party_id; // vendor_id or customer_id
  final List<LedgerRow> rows;
  final double total; // sum of total_amount, rounded to cents

  int get total_qty => rows.fold(0, (sum, r) => sum + r.qty.abs());
}
