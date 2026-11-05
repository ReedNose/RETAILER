import '../models/ledger_row.dart';
import '../models/payment.dart';
import 'balance_before_date.dart';

/// What a customer owes right now, including today's sales and payments.
/// "Balance before tomorrow" is the same thing, so we reuse that one function.
double current_balance({
  required List<LedgerRow> ledger,
  required List<Payment> payments,
  required String customer_id,
  required DateTime now,
}) =>
    balance_before_date(
      ledger: ledger,
      payments: payments,
      customer_id: customer_id,
      day: DateTime(now.year, now.month, now.day + 1),
    );
