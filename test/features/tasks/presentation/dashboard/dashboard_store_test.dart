import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dashboard_store.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/task_item.dart';
import 'package:progress_tracker/features/tasks/presentation/task_setup/task_draft.dart';

void main() {
  final today = dateOnly(DateTime.now());

  group('TaskItem Unit Tests', () {
    test('isDueOn daily calculates correctly for custom days', () {
      final task = TaskItem(
        id: '1',
        name: 'Workouts',
        gridColor: const Color(0xFF22C55E),
        frequency: Frequency.daily,
        daysOfWeek: {0, 2, 4}, // Mon, Wed, Fri
      );

      // Check against Monday (weekday = 1 -> 0)
      final monday = DateTime(2026, 11, 9); // Monday
      final tuesday = DateTime(2026, 11, 10); // Tuesday
      final wednesday = DateTime(2026, 11, 11); // Wednesday

      expect(task.isDueOn(monday), isTrue);
      expect(task.isDueOn(tuesday), isFalse);
      expect(task.isDueOn(wednesday), isTrue);
    });

    test('isDueOn weekly evaluates only chosen weekday', () {
      final task = TaskItem(
        id: '2',
        name: 'Weekly Planning',
        gridColor: const Color(0xFF8B5CF6),
        frequency: Frequency.weekly,
        daysOfWeek: {6}, // Sunday
      );

      final sunday = DateTime(2026, 11, 15);
      final saturday = DateTime(2026, 11, 14);

      expect(task.isDueOn(sunday), isTrue);
      expect(task.isDueOn(saturday), isFalse);
    });

    test('isDueOn monthly handles fixed day and clamps to end of month', () {
      final task = TaskItem(
        id: '3',
        name: '31st Review',
        gridColor: const Color(0xFF06B6D4),
        frequency: Frequency.monthly,
        monthDay: 31,
      );

      // 31st of October (has 31 days)
      expect(task.isDueOn(DateTime(2026, 10, 31)), isTrue);
      expect(task.isDueOn(DateTime(2026, 10, 30)), isFalse);

      // 31st clamped to 30th of November (30 days)
      expect(task.isDueOn(DateTime(2026, 11, 30)), isTrue);

      // 31st clamped to 28th of Feb (non-leap year 2027)
      expect(task.isDueOn(DateTime(2027, 2, 28)), isTrue);
      expect(task.isDueOn(DateTime(2027, 2, 27)), isFalse);
    });

    test('isDueOn monthly with kEndOfMonth always lands on last day', () {
      final task = TaskItem(
        id: '4',
        name: 'End of Month Accounting',
        gridColor: const Color(0xFFF59E0B),
        frequency: Frequency.monthly,
        monthDay: kEndOfMonth,
      );

      expect(task.isDueOn(DateTime(2026, 2, 28)), isTrue); // Feb 28
      expect(task.isDueOn(DateTime(2026, 4, 30)), isTrue); // Apr 30
      expect(task.isDueOn(DateTime(2026, 5, 31)), isTrue); // May 31
      expect(task.isDueOn(DateTime(2026, 5, 30)), isFalse);
    });

    test('cellState evaluates future, rest, done, pending, and missed states', () {
      final createdAt = addDays(today, -10);
      final task = TaskItem(
        id: '5',
        name: 'Habit',
        gridColor: const Color(0xFF22C55E),
        createdAt: createdAt,
        frequency: Frequency.daily,
        daysOfWeek: {today.weekday - 1}, // due today only
      );

      // Future day
      expect(task.cellState(addDays(today, 1), today), CellState.future);

      // Day before createdAt
      expect(task.cellState(addDays(createdAt, -1), today), CellState.rest);

      // Today before done
      expect(task.cellState(today, today), CellState.pending);

      // Today after done
      task.entries[today] = EntryStatus.done;
      expect(task.cellState(today, today), CellState.done);

      // Past scheduled day missed
      final pastScheduled = addDays(today, -7);
      expect(task.cellState(pastScheduled, today), CellState.missed);

      // Past non-scheduled day
      final pastNonScheduled = addDays(today, -1);
      expect(task.cellState(pastNonScheduled, today), CellState.rest);
    });

    test('streak calculations count consecutive scheduled days only', () {
      final task = TaskItem(
        id: '6',
        name: 'Daily Reading',
        gridColor: const Color(0xFF22C55E),
        createdAt: addDays(today, -30),
      );

      // 4 consecutive done days
      for (var i = 1; i <= 4; i++) {
        task.entries[addDays(today, -i)] = EntryStatus.done;
      }
      expect(task.currentStreak, 4);

      // Unreviewed yesterday with includeInMorningReview does not break streak
      final taskWithReview = TaskItem(
        id: '7',
        name: 'Reviewable',
        gridColor: const Color(0xFF22C55E),
        createdAt: addDays(today, -30),
        includeInMorningReview: true,
      );
      for (var i = 2; i <= 5; i++) {
        taskWithReview.entries[addDays(today, -i)] = EntryStatus.done;
      }
      expect(taskWithReview.currentStreak, 4);

      // But missed yesterday breaks streak
      taskWithReview.entries[addDays(today, -1)] = EntryStatus.missed;
      expect(taskWithReview.currentStreak, 0);
    });

    test('timeLabel formats 12-hour AM/PM correctly', () {
      final t1 = TaskItem(
        id: 't1',
        name: 'Early Morning',
        gridColor: const Color(0xFF22C55E),
        startMinutes: 0, // 00:00
      );
      expect(t1.timeLabel, '12:00 AM');

      final t2 = TaskItem(
        id: 't2',
        name: 'Noon',
        gridColor: const Color(0xFF22C55E),
        startMinutes: 12 * 60, // 12:00
      );
      expect(t2.timeLabel, '12:00 PM');

      final t3 = TaskItem(
        id: 't3',
        name: 'Evening',
        gridColor: const Color(0xFF22C55E),
        startMinutes: 21 * 60 + 45, // 21:45
      );
      expect(t3.timeLabel, '09:45 PM');

      final t4 = TaskItem(
        id: 't4',
        name: 'No Time',
        gridColor: const Color(0xFF22C55E),
        startMinutes: null,
      );
      expect(t4.timeLabel, isNull);
    });

    test('scheduleLabel formats every cadence permutation', () {
      // Everyday
      final everyday = TaskItem(
        id: 'e',
        name: 'Everyday',
        gridColor: const Color(0xFF22C55E),
        daysOfWeek: {0, 1, 2, 3, 4, 5, 6},
      );
      expect(everyday.scheduleLabel, 'Every day');

      // Weekdays
      final weekdays = TaskItem(
        id: 'wd',
        name: 'Weekdays',
        gridColor: const Color(0xFF22C55E),
        daysOfWeek: {0, 1, 2, 3, 4},
      );
      expect(weekdays.scheduleLabel, 'Weekdays');

      // Weekends
      final weekends = TaskItem(
        id: 'we',
        name: 'Weekends',
        gridColor: const Color(0xFF22C55E),
        daysOfWeek: {5, 6},
      );
      expect(weekends.scheduleLabel, 'Weekends');

      // Custom
      final custom = TaskItem(
        id: 'c',
        name: 'MWF',
        gridColor: const Color(0xFF22C55E),
        daysOfWeek: {0, 2, 4},
      );
      expect(custom.scheduleLabel, 'Mon, Wed, Fri');

      // Weekly
      final weekly = TaskItem(
        id: 'w',
        name: 'Sunday Run',
        gridColor: const Color(0xFF22C55E),
        frequency: Frequency.weekly,
        daysOfWeek: {6},
      );
      expect(weekly.scheduleLabel, 'Every Sunday');

      // Monthly day
      final monthlyDay = TaskItem(
        id: 'm1',
        name: 'Day 15',
        gridColor: const Color(0xFF22C55E),
        frequency: Frequency.monthly,
        monthDay: 15,
      );
      expect(monthlyDay.scheduleLabel, '15th of month');

      // Monthly end
      final monthlyEnd = TaskItem(
        id: 'me',
        name: 'End',
        gridColor: const Color(0xFF22C55E),
        frequency: Frequency.monthly,
        monthDay: kEndOfMonth,
      );
      expect(monthlyEnd.scheduleLabel, 'Month-end');
    });
  });

  group('DashboardStore Unit Tests', () {
    test('theme toggle switches between dark and light', () {
      final store = DashboardStore();
      expect(store.isDark, isTrue);

      store.toggleTheme();
      expect(store.isDark, isFalse);

      store.toggleTheme();
      expect(store.isDark, isTrue);
    });

    test('setStatus notifies listeners and invokes onStatusChanged', () {
      TaskItem? capturedTask;
      DateTime? capturedDate;
      EntryStatus? capturedStatus;

      final store = DashboardStore(
        onStatusChanged: (task, day, status) {
          capturedTask = task;
          capturedDate = day;
          capturedStatus = status;
        },
      );

      final task = TaskItem(
        id: 'test',
        name: 'Test Task',
        gridColor: const Color(0xFF22C55E),
      );
      store.add(task);

      var listenerNotified = false;
      store.addListener(() => listenerNotified = true);

      store.setStatus(task, today, EntryStatus.done);

      expect(listenerNotified, isTrue);
      expect(capturedTask?.id, 'test');
      expect(capturedDate, today);
      expect(capturedStatus, EntryStatus.done);
      expect(task.entries[today], EntryStatus.done);

      // Clearing status
      store.setStatus(task, today, null);
      expect(task.entries[today], isNull);
      expect(capturedStatus, isNull);
    });

    test('dueToday and doneToday count accurately', () {
      final dueAndDone = TaskItem(
        id: 'd1',
        name: 'Done Task',
        gridColor: const Color(0xFF22C55E),
        daysOfWeek: {today.weekday - 1},
        entries: {today: EntryStatus.done},
      );

      final dueNotDone = TaskItem(
        id: 'd2',
        name: 'Pending Task',
        gridColor: const Color(0xFF22C55E),
        daysOfWeek: {today.weekday - 1},
      );

      final notDue = TaskItem(
        id: 'd3',
        name: 'Other Day Task',
        gridColor: const Color(0xFF22C55E),
        daysOfWeek: {(today.weekday + 2) % 7},
      );

      final store = DashboardStore(tasks: [dueAndDone, dueNotDone, notDue]);

      expect(store.dueToday.length, 2);
      expect(store.doneToday, 1);
    });

    test('consistency calculates 30-day completion percentage', () {
      final store = DashboardStore();
      expect(store.consistency, 0.0);

      final task = TaskItem(
        id: 'c',
        name: 'Consistency Habit',
        gridColor: const Color(0xFF22C55E),
        createdAt: addDays(today, -20),
      );

      // 10 done, 10 missed over past 20 days
      for (var i = 1; i <= 10; i++) {
        task.entries[addDays(today, -i)] = EntryStatus.done;
      }
      for (var i = 11; i <= 20; i++) {
        task.entries[addDays(today, -i)] = EntryStatus.missed;
      }

      store.add(task);
      // 10 done out of 20 scheduled
      expect(store.consistency, closeTo(0.5, 0.01));
    });

    test('last7 returns 7 entries representing recent days', () {
      final store = DashboardStore();
      expect(store.last7.length, 7);

      final task = TaskItem(
        id: 'l7',
        name: 'Daily',
        gridColor: const Color(0xFF22C55E),
        createdAt: addDays(today, -30),
      );
      // Mark all past 7 days done
      for (var i = 0; i < 7; i++) {
        task.entries[addDays(today, -i)] = EntryStatus.done;
      }
      store.add(task);

      final rates = store.last7;
      expect(rates.length, 7);
      expect(rates.every((r) => r == 1.0), isTrue);
    });

    test('syncFromTasks replaces existing task list and notifies', () {
      final store = DashboardStore(tasks: [
        TaskItem(id: 'old', name: 'Old', gridColor: const Color(0xFF22C55E))
      ]);

      var notified = false;
      store.addListener(() => notified = true);

      store.syncFromTasks([
        TaskItem(id: 'new1', name: 'New 1', gridColor: const Color(0xFF22C55E)),
        TaskItem(id: 'new2', name: 'New 2', gridColor: const Color(0xFF8B5CF6)),
      ]);

      expect(notified, isTrue);
      expect(store.tasks.length, 2);
      expect(store.tasks.first.name, 'New 1');
    });
  });
}
