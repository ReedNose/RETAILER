import '../../core/first_or_null.dart';

/// One choice in a searchable dropdown. [value] is what the form stores.
class SearchableOption<T> {
  const SearchableOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
  });

  final T value;
  final String label;
  final String? subtitle;
  final String? leading; // emoji
}

/// The option whose value is [value], or null. Works for the "All" option too,
/// because its value is null.
SearchableOption<T>? option_for<T>(List<SearchableOption<T>> options, T? value) =>
    first_where_or_null(options, (o) => o.value == value);
