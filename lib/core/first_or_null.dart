/// First item that passes [test], or null when none does.
/// Written out here so the app does not depend on a collection extension
/// whose availability depends on the Dart SDK version.
T? first_where_or_null<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}
