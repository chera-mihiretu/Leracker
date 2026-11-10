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
}

