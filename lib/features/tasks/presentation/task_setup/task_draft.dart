import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'motion.dart';

/// How often the task repeats.
enum Frequency { daily, weekly, monthly }

/// Sub-options when [Frequency.daily] is chosen.
enum Cadence { everyDay, weekdays, weekends, custom }

/// Special value for [TaskDraft.monthDay]: the last day of the month.
const int kEndOfMonth = -1;

enum DayWindow { morning, afternoon, evening }

/// Everything the user picks during setup. Pages listen and update it.
class TaskDraft extends ChangeNotifier {
  String name = '';
  Frequency frequency = Frequency.daily;
  int weekDay = 0; // weekly: 0 = Monday … 6 = Sunday
  int monthDay = 1; // monthly: 1–31, or kEndOfMonth
  Cadence cadence = Cadence.everyDay;
  Set<int> days = {0, 1, 2, 3, 4, 5, 6}; // 0 = Monday
  int minutes = 8 * 60;
  int nudges = 1;
  Color color = PT.emerald;
  bool morningReview = true;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  DayWindow get window {
    final h = minutes ~/ 60;
    if (h < 12) return DayWindow.morning;
    if (h < 17) return DayWindow.afternoon;
    return DayWindow.evening;
  }

  static Set<int> daysFor(Cadence c, Set<int> current) => switch (c) {
        Cadence.everyDay => {0, 1, 2, 3, 4, 5, 6},
        Cadence.weekdays => {0, 1, 2, 3, 4},
        Cadence.weekends => {5, 6},
        Cadence.custom => current,
      };

  static const weekDayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static String ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
  }

  String get scheduleLabel => switch (frequency) {
        Frequency.daily => switch (cadence) {
            Cadence.everyDay => 'Every day',
            Cadence.weekdays => 'Weekdays',
            Cadence.weekends => 'Weekends',
            Cadence.custom => '${days.length}× a week',
          },
        Frequency.weekly => 'Every ${weekDayNames[weekDay]}',
        Frequency.monthly => monthDay == kEndOfMonth
            ? 'End of month'
            : monthDay == 1
                ? 'Start of month'
                : 'Monthly on the ${ordinal(monthDay)}',
      };

  /// Is the task due on [date]?
  bool isDueOn(DateTime date) {
    switch (frequency) {
      case Frequency.daily:
        return days.contains(date.weekday - 1);
      case Frequency.weekly:
        return date.weekday - 1 == weekDay;
      case Frequency.monthly:
        final last = DateTime(date.year, date.month + 1, 0).day;
        final target = monthDay == kEndOfMonth ? last : (monthDay > last ? last : monthDay);
        return date.day == target;
    }
  }

  String get timeLabel {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
