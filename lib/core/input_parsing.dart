/// Parses a typed whole number. Returns null when it is not a positive number.
int? parse_positive_int(String text) {
  final value = int.tryParse(text.trim());
  if (value == null || value <= 0) return null;
  return value;
}

/// Parses a typed price or cost. Zero is allowed (free stock), negatives are not.
/// A comma is accepted as the decimal separator.
double? parse_money(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || value < 0) return null;
  return value;
}
