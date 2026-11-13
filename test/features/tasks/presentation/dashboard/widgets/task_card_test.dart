import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dash_theme.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dashboard_store.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/task_item.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/heatmap.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/task_card.dart';

void main() {
  final today = dateOnly(DateTime.now());

  Widget buildWidget({
    required TaskItem task,
    required DashboardStore store,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DashTheme(
          palette: DashPalette.dark,
          child: DashTaskCard(
            task: task,
            store: store,
          ),
        ),
      ),
    );
  }

  testWidgets('DashTaskCard renders title, schedule pill, streak, and Heatmap',
      (tester) async {
    final task = TaskItem(
      id: 'c1',
      name: 'Card Test Habit',
      gridColor: const Color(0xFF22C55E),
      daysOfWeek: {0, 1, 2, 3, 4, 5, 6},
      startMinutes: 8 * 60 + 30, // 08:30 AM
      createdAt: addDays(today, -20),
    );
    // Add 5 day streak
    for (var i = 1; i <= 5; i++) {
      task.entries[addDays(today, -i)] = EntryStatus.done;
    }

    final store = DashboardStore(tasks: [task]);

    await tester.pumpWidget(buildWidget(task: task, store: store));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Card Test Habit'), findsOneWidget);
    expect(find.text('Every day · 08:30 AM'), findsOneWidget);
    expect(find.text('5d'), findsOneWidget);
    expect(find.byType(Heatmap), findsOneWidget);
    expect(find.byType(QuickCheck), findsOneWidget);
  });

  testWidgets('QuickCheck tap toggles today status when task is due today',
      (tester) async {
    final task = TaskItem(
      id: 'c2',
      name: 'Checkable Habit',
      gridColor: const Color(0xFF22C55E),
      daysOfWeek: {today.weekday - 1}, // due today
      createdAt: addDays(today, -5),
    );
    final store = DashboardStore(tasks: [task]);

    await tester.pumpWidget(buildWidget(task: task, store: store));
    await tester.pump(const Duration(milliseconds: 300));

    expect(task.isCompletedToday, isFalse);

    // Tap quick check to complete
    await tester.tap(find.byType(QuickCheck));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(task.isCompletedToday, isTrue);

    // Tap quick check again to toggle off
    await tester.tap(find.byType(QuickCheck));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(task.isCompletedToday, isFalse);
  });

  testWidgets('QuickCheck tap does nothing when task is not due today',
      (tester) async {
    final task = TaskItem(
      id: 'c3',
      name: 'Not Due Habit',
      gridColor: const Color(0xFF22C55E),
      daysOfWeek: {(today.weekday + 3) % 7}, // not due today
      createdAt: addDays(today, -5),
    );
    final store = DashboardStore(tasks: [task]);

    await tester.pumpWidget(buildWidget(task: task, store: store));
    await tester.pump(const Duration(milliseconds: 300));

    expect(task.isDueToday, isFalse);

    await tester.tap(find.byType(QuickCheck));
    await tester.pump();

    expect(task.isCompletedToday, isFalse);
  });

  testWidgets(
      'showCellSheet on past day displays read-only info and cannot be edited',
      (tester) async {
    final pastDay = addDays(today, -5);
    final task = TaskItem(
      id: 'past-task',
      name: 'Past Day Habit',
      gridColor: const Color(0xFF22C55E),
      createdAt: addDays(today, -10),
      entries: {pastDay: EntryStatus.done},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashTheme(
            palette: DashPalette.dark,
            child: Builder(builder: (context) {
              return TextButton(
                onPressed: () => showCellSheet(
                  context: context,
                  task: task,
                  day: pastDay,
                  onSet: (_) {},
                ),
                child: const Text('Open Sheet'),
              );
            }),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Past Day Habit'), findsOneWidget);
    expect(find.text('Past entries cannot be edited'), findsOneWidget);
    expect(find.text('Status: Completed'), findsOneWidget);

    // Edit options should NOT exist
    expect(find.text('Done'), findsNothing);
    expect(find.text('Missed'), findsNothing);
    expect(find.text('Reset'), findsNothing);
  });

  testWidgets(
      'showCellSheet on today displays editable options Done, Missed, and Reset',
      (tester) async {
    EntryStatus? selectedStatus;
    final task = TaskItem(
      id: 'today-task',
      name: 'Today Habit',
      gridColor: const Color(0xFF22C55E),
      createdAt: addDays(today, -10),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashTheme(
            palette: DashPalette.dark,
            child: Builder(builder: (context) {
              return TextButton(
                onPressed: () => showCellSheet(
                  context: context,
                  task: task,
                  day: today,
                  onSet: (s) => selectedStatus = s,
                ),
                child: const Text('Open Sheet'),
              );
            }),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Today Habit'), findsOneWidget);
    expect(find.text('Past entries cannot be edited'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(selectedStatus, EntryStatus.done);
  });
}
