import "date_helpers.dart";

/// How many days old a batch is today (0 = bought today).
int batch_age_in_days(DateTime batch_date, DateTime today) =>
    days_between(batch_date, today);

/// A batch is "priority" on its last day of shelf life.
/// With the default shelf_life_days of 2 this is the classic "Day 2" rule.
bool is_priority_batch({
  required DateTime batch_date,
  required int shelf_life_days,
  required DateTime today,
}) {
  return batch_age_in_days(batch_date, today) >= shelf_life_days - 1;
}

/// Friendly label for the retailer list.
String batch_age_label(DateTime batch_date, DateTime today) {
  final age = batch_age_in_days(batch_date, today);
  if (age <= 0) return "Today";
  if (age == 1) return "Yesterday";
  return "$age days ago";
}
