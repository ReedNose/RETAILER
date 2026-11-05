import '../models/ledger_row.dart';

/// Sum of total_amount for one transaction type. total_amount is always positive,
/// so the type decides the direction.
double sum_amounts(List<LedgerRow> rows, TransactionType type) => rows
    .where((row) => row.transaction_type == type)
    .fold(0.0, (sum, row) => sum + row.total_amount);
