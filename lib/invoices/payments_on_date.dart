import '../core/date_helpers.dart';
import '../models/payment.dart';
import 'round_money.dart';

/// Total a customer paid on one day.
double payments_on_date({
  required List<Payment> payments,
  required String customer_id,
  required DateTime day,
}) =>
    round_money(payments
        .where((p) => p.customer_id == customer_id && is_same_date(p.date, day))
        .fold(0.0, (sum, p) => sum + p.amount));
