// Append-only history. Never edit or delete a row; add a correcting row instead.

enum TransactionType { sale, purchase, spoilage }

enum SourceType { customer, vendor }

extension TransactionTypeDb on TransactionType {
  String get db_value => name.toUpperCase(); // SALE | PURCHASE | SPOILAGE
}

extension SourceTypeDb on SourceType {
  String get db_value => name.toUpperCase(); // CUSTOMER | VENDOR
}

class LedgerRow {
  const LedgerRow({
    required this.transaction_id,
    required this.created_at,
    required this.date,
    required this.transaction_type,
    required this.source_type,
    required this.source_id,
    required this.batch_id,
    required this.qty,
    required this.unit_price,
    required this.total_amount,
  });

  final String transaction_id;
  final DateTime created_at;
  final DateTime date; // real date column used by every report filter
  final TransactionType transaction_type;
  final SourceType source_type;
  final String source_id;
  final String batch_id; // contains the embedded SKU
  final int qty; // positive = incoming, negative = outgoing
  final double unit_price;
  final double total_amount; // always positive; the type gives the direction

  String get sku => batch_id.split("_").first;
}
