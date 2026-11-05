// Money paid to a vendor (purchase invoice) or received from a customer
// (sales invoice), tied to one invoice by its transaction_id. Append-only.

class InvoicePayment {
  const InvoicePayment({
    required this.payment_id,
    required this.created_at,
    required this.date,
    required this.transaction_id,
    required this.amount,
  });

  final String payment_id;
  final DateTime created_at;
  final DateTime date;
  final String transaction_id;
  final double amount; // always positive
}
