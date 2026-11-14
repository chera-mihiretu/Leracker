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

    // M, T, W, T, F, S, S row labels
    expect(find.text('M'), findsOneWidget);
    expect(find.text('T'), findsNWidgets(2));
    expect(find.text('W'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
    expect(find.text('S'), findsNWidgets(2));
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

  testWidgets(
      'showCellSheet on today displays read-only info when task is not scheduled today',
      (tester) async {
    final task = TaskItem(
      id: 'not-due-task',
      name: 'Other Day Habit',
      gridColor: const Color(0xFF22C55E),
      daysOfWeek: {(today.weekday + 2) % 7}, // not scheduled today
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

    expect(find.text('Other Day Habit'), findsOneWidget);
    expect(find.text('Status: Not scheduled'), findsOneWidget);
    expect(find.text('This task is not scheduled for today'), findsOneWidget);

    // Edit options should NOT exist
    expect(find.text('Done'), findsNothing);
    expect(find.text('Missed'), findsNothing);
    expect(find.text('Reset'), findsNothing);
  });

  testWidgets(
      'Heatmap dropdown shows multiple years when task createdAt is in 2026 and currentDate is in 2027',
      (tester) async {
    final task2026 = TaskItem(
      id: 'h2026',
      name: '2026 Habit',
      gridColor: const Color(0xFF22C55E),
      createdAt: DateTime(2026, 10, 14),
    );
    final simulated2027 = DateTime(2027, 4, 15);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashTheme(
            palette: DashPalette.dark,
            child: Heatmap(
              task: task2026,
              currentDate: simulated2027,
              onCellTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final yearSelector = find.byKey(const Key('heatmap_year_selector'));
    expect(yearSelector, findsOneWidget);

    // Tap dropdown to view year options
    await tester.tap(yearSelector);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify 2026 and 2027 options are listed
    expect(find.widgetWithText(DropdownMenuItem<int>, '2026'), findsOneWidget);
    expect(find.widgetWithText(DropdownMenuItem<int>, '2027'), findsWidgets);

    // Select 2026
    await tester.tap(find.widgetWithText(DropdownMenuItem<int>, '2026'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Year selector now displays 2026
    final dropdown = tester.widget<DropdownButton<int>>(yearSelector);
    expect(dropdown.value, 2026);
  });

  testWidgets('Heatmap ignores taps on dates prior to task.createdAt',
      (tester) async {
    // Nov 11, 2026 is Wednesday (weekday 3, row index 2 in 0-indexed Mon-Sun).
    // Monday Nov 9 (row 0) and Tuesday Nov 10 (row 1) are before task createdAt.
    final taskCreatedWed = TaskItem(
      id: 'h-wed',
      name: 'Wednesday Habit',
      gridColor: const Color(0xFF22C55E),
      createdAt: DateTime(2026, 11, 11),
    );
    final simulatedToday = DateTime(2026, 11, 14); // Saturday

    DateTime? tappedDay;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashTheme(
            palette: DashPalette.dark,
            child: Heatmap(
              task: taskCreatedWed,
              currentDate: simulatedToday,
              onCellTap: (d) => tappedDay = d,
            ),
          ),
        ),
      ),
    );

    // Find CustomPaint inside Heatmap
    final customPaint = find.byType(CustomPaint).last;

    // Row 0 (Monday Nov 9, before createdAt): step is 16px (13 + 3)
    // Tap at dx: 8 (col 0), dy: 8 (row 0)
    await tester.tapAt(tester.getTopLeft(customPaint) + const Offset(8, 8));
    await tester.pump();
    expect(tappedDay, isNull);

    // Row 2 (Wednesday Nov 11, on createdAt): dy = 2 * 16 + 8 = 40
    await tester.tapAt(tester.getTopLeft(customPaint) + const Offset(8, 40));
    await tester.pump();
    expect(tappedDay, DateTime(2026, 11, 11));
  });
}
