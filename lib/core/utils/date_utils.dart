/// Date helper utilities for the progress tracker.
class AppDateUtils {
  AppDateUtils._();

  /// Returns the date with time stripped (midnight).
  static DateTime dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Returns true if [a] and [b] represent the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns the number of days between [start] and [end].
  static int daysBetween(DateTime start, DateTime end) {
    return dateOnly(end).difference(dateOnly(start)).inDays;
  }
}
