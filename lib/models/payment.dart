// Money received from a customer. Append-only like the ledger: rows are never
// edited or deleted. Payments live in their own table (not in the ledger) so
// every existing report stays exactly as it was.

class Payment {
  const Payment({
    required this.payment_id,
    required this.created_at,
    required this.date,
    required this.customer_id,
    required this.amount,
  });

  final String payment_id;
  final DateTime created_at;
  final DateTime date; // date-only, same idea as LedgerRow.date
  final String customer_id;
  final double amount; // always positive
}
