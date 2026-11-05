import '../core/date_helpers.dart';
import '../models/ledger_row.dart';

/// The SALE rows of one customer on one day. These become the invoice lines.
List<LedgerRow> sales_rows_for_customer_on({
  required List<LedgerRow> ledger,
  required String customer_id,
  required DateTime day,
}) =>
    ledger
        .where((row) =>
            row.transaction_type == TransactionType.sale &&
            row.source_type == SourceType.customer &&
            row.source_id == customer_id &&
            is_same_date(row.date, day))
        .toList();
