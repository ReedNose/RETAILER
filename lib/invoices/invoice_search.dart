import 'ledger_invoice.dart';
import 'round_money.dart';

/// Money still open on one invoice given what has been paid, never below zero.
double open_amount_of(LedgerInvoice invoice, double paid) {
  final open = round_money(invoice.total - round_money(paid));
  return open < 0 ? 0 : open;
}

/// True when the query matches the invoice number or the party name (not case-sensitive).
/// An empty query matches every invoice.
bool invoice_matches_query(LedgerInvoice invoice, String party_name, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return invoice.transaction_id.toLowerCase().contains(needle) ||
      party_name.toLowerCase().contains(needle);
}
