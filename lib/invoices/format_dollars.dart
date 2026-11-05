import 'format_money.dart';

/// 1234.5 prints with a dollar sign and thousands separators, and a negative
/// amount (a credit) keeps its minus in front of the dollar sign.
/// Helvetica, the default PDF font, can draw the dollar sign.
String format_dollars(double value) {
  final sign = value < 0 ? '-' : '';
  return '$sign\$${format_money(value.abs())}';
}
