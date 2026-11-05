/// One id for a whole group of ledger rows (one pickup, one purchase run).
/// Every row that shares it belongs to the same invoice.
String new_transaction_id() =>
    'TRX${DateTime.now().microsecondsSinceEpoch.toRadixString(36).toUpperCase()}';
