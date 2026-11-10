import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dash_theme.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dashboard_store.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/task_item.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/morning_review.dart';

void main() {
  final today = dateOnly(DateTime.now());
  final yesterday = addDays(today, -1);

  TaskItem createUnreviewedTask(String id, String name) {
    return TaskItem(
      id: id,
      name: name,
      gridColor: const Color(0xFF22C55E),
      createdAt: addDays(today, -10),
      includeInMorningReview: true,
      daysOfWeek: {yesterday.weekday - 1}, // scheduled on yesterday
    );
  }

  testWidgets('MorningReview tap buttons answer tasks sequentially and reach caught up',
      (tester) async {
    final t1 = createUnreviewedTask('t1', 'First Habit');
    final t2 = createUnreviewedTask('t2', 'Second Habit');
    final store = DashboardStore(tasks: [t1, t2]);

    expect(store.toReview.length, 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashTheme(
            palette: DashPalette.dark,
            child: MorningReview(store: store),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('First Habit'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);

    // Answer Done for First Habit
    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(t1.statusOn(yesterday), EntryStatus.done);
    expect(find.text('Second Habit'), findsOneWidget);

    // Answer Missed for Second Habit
    await tester.tap(find.text('Missed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(t2.statusOn(yesterday), EntryStatus.missed);
    expect(store.toReview, isEmpty);
    expect(find.text('All caught up'), findsOneWidget);

    // Advance past the 1300ms auto-close timer
    await tester.pump(const Duration(milliseconds: 1400));
  });

  testWidgets('MorningReview swipe gesture answers task (swipe right = done, swipe left = missed)',
      (tester) async {
    final t1 = createUnreviewedTask('s1', 'Swipe Habit 1');
    final t2 = createUnreviewedTask('s2', 'Swipe Habit 2');
    final store = DashboardStore(tasks: [t1, t2]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashTheme(
            palette: DashPalette.dark,
            child: MorningReview(store: store),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Swipe Habit 1'), findsOneWidget);

    // Drag right by +150px to trigger Done
    await tester.drag(find.text('Swipe Habit 1'), const Offset(150, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(t1.statusOn(yesterday), EntryStatus.done);
    expect(find.text('Swipe Habit 2'), findsOneWidget);

    // Drag left by -150px to trigger Missed
    await tester.drag(find.text('Swipe Habit 2'), const Offset(-150, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(t2.statusOn(yesterday), EntryStatus.missed);
    expect(find.text('All caught up'), findsOneWidget);

    // Advance past the 1300ms auto-close timer
    await tester.pump(const Duration(milliseconds: 1400));
  });
}
