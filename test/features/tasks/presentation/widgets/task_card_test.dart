import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entity.dart';
import 'package:progress_tracker/features/tasks/presentation/widgets/green_grid.dart';
import 'package:progress_tracker/features/tasks/presentation/widgets/task_card.dart';

void main() {
  final now = DateTime.now();
  final task = TaskEntity(
    id: 't1',
    userId: 'u1',
    name: 'Morning Run',
    createdAt: now.subtract(const Duration(days: 30)),
  );

  testWidgets('renders task name and GreenGrid only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            entries: const [],
            onSetStatus: (date, status) {},
          ),
        ),
      ),
    );

    expect(find.text('Morning Run'), findsOneWidget);
    expect(find.byType(GreenGrid), findsOneWidget);
  });

  testWidgets('tapping a past cell shows read-only info and cannot be edited', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            entries: const [],
            onSetStatus: (date, status) {},
          ),
        ),
      ),
    );

    // Tap a past cell in the GreenGrid (yesterday)
    final yesterday = now.subtract(const Duration(days: 1));
    final pastCell = find.byKey(ValueKey(
      'green_grid_cell_${yesterday.year}_${yesterday.month}_${yesterday.day}',
    ));
    await tester.tap(pastCell);
    await tester.pumpAndSettle();

    // Read-only indicator should appear
    expect(find.text('Past entries cannot be edited'), findsOneWidget);
    // Edit buttons should NOT exist
    expect(find.text('Done'), findsNothing);
    expect(find.text('Missed'), findsNothing);
  });

  testWidgets('tapping today cell allows setting Done and triggers callback', (tester) async {
    String? chosenStatus;
    DateTime? chosenDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: task,
            entries: const [],
            onSetStatus: (date, status) {
              chosenDate = date;
              chosenStatus = status;
            },
          ),
        ),
      ),
    );

    // Tap today cell in the GreenGrid
    final today = DateTime(now.year, now.month, now.day);
    final todayCell = find.byKey(ValueKey(
      'green_grid_cell_${today.year}_${today.month}_${today.day}',
    ));
    await tester.tap(todayCell);
    await tester.pumpAndSettle();

    // Bottom sheet should open with Done and Missed buttons for today
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(chosenStatus, 'done');
    expect(chosenDate, isNotNull);
  });

  testWidgets('tapping today cell shows read-only message when task is not scheduled for today', (tester) async {
    final notDueTask = TaskEntity(
      id: 't-not-due',
      userId: 'u1',
      name: 'Weekend Run',
      createdAt: now,
      frequencyType: 'daily',
      daysOfWeek: [(now.weekday % 7) + 1], // different day of the week
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: notDueTask,
            entries: const [],
            onSetStatus: (date, status) {},
          ),
        ),
      ),
    );

    // Tap today cell in the GreenGrid
    final today = DateTime(now.year, now.month, now.day);
    final todayCell = find.byKey(ValueKey(
      'green_grid_cell_${today.year}_${today.month}_${today.day}',
    ));
    await tester.tap(todayCell);
    await tester.pumpAndSettle();

    // Bottom sheet should show read-only info and NOT show Done/Missed
    expect(find.text('This task is not scheduled for today'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(find.text('Missed'), findsNothing);
  });
}
