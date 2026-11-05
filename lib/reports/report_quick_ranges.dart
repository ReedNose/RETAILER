import '../core/date_helpers.dart';

/// Inclusive start and end day.
typedef DateSpan = ({DateTime start, DateTime end});

DateSpan quick_range_today(DateTime now) {
  final day = date_only(now);
  return (start: day, end: day);
}

/// Monday to Sunday of the current week.
DateSpan quick_range_this_week(DateTime now) {
  final day = date_only(now);
  final monday = day.subtract(Duration(days: day.weekday - DateTime.monday));
  return (start: monday, end: monday.add(const Duration(days: 6)));
}

/// First to last day of the current month.
DateSpan quick_range_this_month(DateTime now) {
  final day = date_only(now);
  return (
    start: DateTime(day.year, day.month, 1),
    end: DateTime(day.year, day.month + 1, 0),
  );
}
