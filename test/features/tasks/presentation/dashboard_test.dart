import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dashboard_screen.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dashboard_store.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/task_item.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/task_card.dart';
import 'package:progress_tracker/features/tasks/presentation/task_setup/task_draft.dart';

void main() {
  final today = dateOnly(DateTime.now());

  test('streak counts scheduled days and ignores rest days', () {
    final t = TaskItem(
      id: 'a',
      name: 'Read',
      gridColor: const Color(0xFF8B5CF6),
      createdAt: addDays(today, -60),
    );
    for (var i = 1; i <= 5; i++) {
      t.entries[addDays(today, -i)] = EntryStatus.done;
    }
    t.entries[addDays(today, -6)] = EntryStatus.missed;
    expect(t.currentStreak, 5); // today pending doesn't break it
    t.entries[today] = EntryStatus.done;
    expect(t.currentStreak, 6);
  });

  test('labels and JSON round-trip match the backend shape', () {
    final t = TaskItem(
      id: 'b',
      name: 'Budget',
      gridColor: const Color(0xFFF59E0B),
      frequency: Frequency.monthly,
      monthDay: kEndOfMonth,
      startMinutes: 7 * 60 + 30,
    );
    expect(t.scheduleLabel, 'Month-end');
    expect(t.timeLabel, '07:30 AM');
    final j = t.toJson();
    expect(j['monthlyRule'], 'end');
    expect(j['startTime'], '07:30:00');
    expect(j['gridColor'], '#F59E0B');
    final back = TaskItem.fromJson(j);
    expect(back.monthDay, kEndOfMonth);
    expect(back.startMinutes, 450);

    final w = TaskItem(
        id: 'c',
        name: 'Run',
        gridColor: const Color(0xFF10B981),
        frequency: Frequency.weekly,
        daysOfWeek: {6});
    expect(w.scheduleLabel, 'Every Sunday');
    expect(w.toJson()['daysOfWeek'], [7]);
  });

  testWidgets('dashboard renders, checks a task and runs morning review',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final store = DashboardStore.sample();
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(store: store)));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Today\'s focus'), findsOneWidget);
    expect(find.text('2 to review'), findsOneWidget);

    // One-tap check on "10,000 Steps" (not done yet today).
    final before = store.doneToday;
    final card = find.ancestor(
        of: find.text('10,000 Steps'), matching: find.byType(DashTaskCard));
    final check = find.descendant(of: card, matching: find.byType(QuickCheck));
    await tester.ensureVisible(check);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(check);
    await tester.pump(const Duration(milliseconds: 700));
    expect(store.doneToday, before + 1);

    // Morning review: answer both.
    await tester.ensureVisible(find.text('2 to review'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('2 to review'), warnIfMissed: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Missed'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(store.toReview, isEmpty);
    expect(find.text('All caught up'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('empty store shows the zero state', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: DashboardScreen(store: DashboardStore())));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Create your first habit'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
