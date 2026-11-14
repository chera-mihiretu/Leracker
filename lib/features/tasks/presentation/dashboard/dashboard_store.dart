// App state for the dashboard. Swap the sample data for your backend.
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../task_setup/task_draft.dart';
import 'task_item.dart';

class DashboardStore extends ChangeNotifier {
  DashboardStore({
    List<TaskItem>? tasks,
    this.onStatusChanged,
  }) : tasks = tasks ?? [];

  final List<TaskItem> tasks;
  final void Function(TaskItem task, DateTime day, EntryStatus? status)? onStatusChanged;
  bool isDark = true;

  DateTime get today => dateOnly(DateTime.now());
  DateTime get yesterday => addDays(today, -1);

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }

  void add(TaskItem t) {
    tasks.insert(0, t);
    notifyListeners();
  }

  void syncFromTasks(List<TaskItem> newTasks) {
    tasks.clear();
    tasks.addAll(newTasks);
    notifyListeners();
  }

  void setStatus(TaskItem t, DateTime day, EntryStatus? status) {
    final d = dateOnly(day);
    if (status == null) {
      t.entries.remove(d);
    } else {
      t.entries[d] = status;
    }
    notifyListeners();
    onStatusChanged?.call(t, d, status);
  }

  void toggleToday(TaskItem t) {
    if (!t.isDueToday) return;
    setStatus(t, today, t.isCompletedToday ? null : EntryStatus.done);
  }

  // ── Dashboard metrics ────────────────────────────────────────────────

  List<TaskItem> get dueToday => tasks.where((t) => t.isDueToday).toList();
  int get doneToday => dueToday.where((t) => t.isCompletedToday).length;

  /// Yesterday's scheduled tasks that still need a Done/Missed answer.
  List<TaskItem> get toReview => tasks
      .where((t) =>
          t.includeInMorningReview &&
          !yesterday.isBefore(t.createdAt) &&
          t.isDueOn(yesterday) &&
          t.statusOn(yesterday) == null)
      .toList();

  /// Done ÷ due across all tasks over the last 30 days (0..1).
  double get consistency {
    var due = 0, done = 0;
    for (var i = 0; i < 30; i++) {
      final d = addDays(today, -i);
      for (final t in tasks) {
        if (d.isBefore(t.createdAt) || !t.isDueOn(d)) continue;
        final s = t.statusOn(d);
        if (i == 0 && s == null) continue; // today still pending
        due++;
        if (s == EntryStatus.done) done++;
      }
    }
    return due == 0 ? 0 : done / due;
  }

  int get bestStreak =>
      tasks.fold(0, (m, t) => math.max(m, t.frequency == Frequency.daily ? t.currentStreak : 0));

  /// Last 7 days (oldest first): share of due tasks completed, or null if
  /// nothing was scheduled that day.
  List<double?> get last7 => [
        for (var i = 6; i >= 0; i--)
          () {
            final d = addDays(today, -i);
            final due = tasks
                .where((t) => !d.isBefore(t.createdAt) && t.isDueOn(d))
                .toList();
            if (due.isEmpty) return null;
            return due.where((t) => t.statusOn(d) == EntryStatus.done).length /
                due.length;
          }(),
      ];

  // ── Sample data ──────────────────────────────────────────────────────

  factory DashboardStore.sample() {
    final rnd = math.Random(7);
    final today = dateOnly(DateTime.now());
    final created = addDays(today, -200);

    TaskItem make(String name, int color, double p, int forceStreak,
        {Frequency f = Frequency.daily,
        Set<int>? days,
        int monthDay = 1,
        int? time,
        bool doneToday = false,
        bool leaveYesterday = false}) {
      final t = TaskItem(
        id: name,
        name: name,
        gridColor: Color(color),
        frequency: f,
        daysOfWeek: days,
        monthDay: monthDay,
        startMinutes: time,
        createdAt: created,
      );
      var forced = 0;
      for (var i = 1; i < 200; i++) {
        final d = addDays(today, -i);
        if (!t.isDueOn(d)) continue;
        if (i == 1 && leaveYesterday) continue;
        final force = forced < forceStreak;
        if (force) forced++;
        t.entries[d] = force || rnd.nextDouble() < p
            ? EntryStatus.done
            : EntryStatus.missed;
      }
      if (doneToday && t.isDueOn(today)) t.entries[today] = EntryStatus.done;
      return t;
    }

    return DashboardStore(tasks: [
      make('Morning Meditation', 0xFF22C55E, 0.85, 18,
          time: 7 * 60 + 30, doneToday: true),
      make('10,000 Steps', 0xFF06B6D4, 0.72, 6, leaveYesterday: true),
      make('Read 30 mins', 0xFF8B5CF6, 0.92, 22,
          days: {0, 2}, time: 21 * 60, doneToday: true),
      make('Long run', 0xFF10B981, 0.8, 5,
          f: Frequency.weekly, days: {6}, time: 6 * 60 + 30),
      make('Monthly budget review', 0xFFF59E0B, 0.9, 4,
          f: Frequency.monthly, monthDay: kEndOfMonth, time: 19 * 60),
      make('Stretch', 0xFF86EFAC, 0.7, 3, leaveYesterday: true, time: 22 * 60),
    ]);
  }
}
