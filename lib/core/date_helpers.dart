// Small date helpers. Everything in this app is date-only (no time of day).

DateTime date_only(DateTime value) => DateTime(value.year, value.month, value.day);

/// Whole days from [from] to [to].
int days_between(DateTime from, DateTime to) {
  // UTC avoids daylight-saving hours skewing the day count.
  final from_utc = DateTime.utc(from.year, from.month, from.day);
  final to_utc = DateTime.utc(to.year, to.month, to.day);
  return to_utc.difference(from_utc).inDays;
}

bool is_same_date(DateTime a, DateTime b) => days_between(a, b) == 0;
