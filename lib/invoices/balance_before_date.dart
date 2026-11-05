import '../core/date_helpers.dart';
import '../models/ledger_row.dart';
import '../models/payment.dart';
import 'round_money.dart';

/// What a customer owed at the START of [day]: every sale before that day
/// minus every payment before that day. Negative means they paid ahead (credit).
double balance_before_date({
  required List<LedgerRow> ledger,
  required List<Payment> payments,
  required String customer_id,
  required DateTime day,
}) {
  final cutoff = date_only(day);

  final sold = ledger
      .where((row) =>
          row.transaction_type == TransactionType.sale &&
          row.source_type == SourceType.customer &&
          row.source_id == customer_id &&
          date_only(row.date).isBefore(cutoff))
      .fold(0.0, (sum, row) => sum + row.total_amount);

  final paid = payments
      .where((p) => p.customer_id == customer_id && date_only(p.date).isBefore(cutoff))
      .fold(0.0, (sum, p) => sum + p.amount);

  return round_money(sold - paid);
}
