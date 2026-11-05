import 'package:intl/intl.dart';

/// 1234.5 becomes "1,234.50". No currency symbol on purpose: the default PDF
/// font cannot draw every symbol, and the spec does not name a currency.
String format_money(double value) => NumberFormat('#,##0.00').format(value);
