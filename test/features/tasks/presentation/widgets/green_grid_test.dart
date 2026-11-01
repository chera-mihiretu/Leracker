import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entry_entity.dart';
import 'package:progress_tracker/features/tasks/presentation/widgets/green_grid.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final testEntries = [
    TaskEntryEntity(
      id: 'e1',
      taskId: 't1',
      userId: 'u1',
      entryDate: today,
      status: 'done',
      answeredAt: today,
    ),
    TaskEntryEntity(
      id: 'e2',
      taskId: 't1',
      userId: 'u1',
      entryDate: yesterday,
      status: 'missed',
      answeredAt: yesterday,
    ),
  ];

  testWidgets('renders grid cells for the given range', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GreenGrid(
            entries: testEntries,
            daysToShow: 14,
          ),
        ),
      ),
    );

    // Should find containers for the cells
    expect(find.byType(GestureDetector), findsWidgets);
  });

  testWidgets('triggers onDayTap when cell is tapped', (tester) async {
    DateTime? tappedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GreenGrid(
            entries: testEntries,
            daysToShow: 7,
            onDayTap: (date) {
              tappedDate = date;
            },
          ),
        ),
      ),
    );

    // Tap the last cell (today)
    final cells = find.byType(GestureDetector);
    await tester.tap(cells.last);
    await tester.pump();

    expect(tappedDate, isNotNull);
    expect(tappedDate?.day, today.day);
  });
}

