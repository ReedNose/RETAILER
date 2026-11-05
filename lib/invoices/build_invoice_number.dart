import 'package:intl/intl.dart';

/// INV-20261104-C001: one invoice per customer per day, so this is stable and
/// re-sending the same day's invoice never creates a new number.
String build_invoice_number({required String customer_id, required DateTime day}) =>
    'INV-${DateFormat('yyyyMMdd').format(day)}-$customer_id';
