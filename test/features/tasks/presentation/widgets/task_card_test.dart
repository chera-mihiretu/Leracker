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
    createdAt: now,
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

    // Tap a past cell in the GreenGrid (first cell is 34 days ago)
    final cells = find.byType(GestureDetector);
    await tester.tap(cells.first);
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

    // Tap today cell in the GreenGrid (last cell)
    final cells = find.byType(GestureDetector);
    await tester.tap(cells.last);
    await tester.pumpAndSettle();

    // Bottom sheet should open with Done and Missed buttons for today
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(chosenStatus, 'done');
    expect(chosenDate, isNotNull);
  });
}
