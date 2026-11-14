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

  testWidgets('renders grid cells and M, T, W, T, F, S, S row labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GreenGrid(entries: testEntries, daysToShow: 14)),
      ),
    );

    // Should find day labels: M, T, W, F, S
    expect(find.text('M'), findsOneWidget);
    expect(find.text('T'), findsNWidgets(2)); // Tuesday and Thursday
    expect(find.text('W'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
    expect(find.text('S'), findsNWidgets(2)); // Saturday and Sunday

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

  testWidgets(
      'does not render any grid cell before task startDate or in future',
      (tester) async {
    // Nov 10, 2026 is Tuesday (weekday 2). Monday of that week is Nov 9.
    final startDate = DateTime(2026, 11, 10);
    final simulatedToday = DateTime(2026, 11, 14); // Saturday

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GreenGrid(
            entries: const [],
            startDate: startDate,
            currentDate: simulatedToday,
          ),
        ),
      ),
    );

    // Monday Nov 9 (before start date): should NOT exist
    expect(
      find.byKey(const ValueKey('green_grid_cell_2026_11_9')),
      findsNothing,
    );

    // Tuesday Nov 10 (on start date): should exist
    expect(
      find.byKey(const ValueKey('green_grid_cell_2026_11_10')),
      findsOneWidget,
    );

    // Saturday Nov 14 (simulated today): should exist
    expect(
      find.byKey(const ValueKey('green_grid_cell_2026_11_14')),
      findsOneWidget,
    );

    // Sunday Nov 15 (future): should NOT exist
    expect(
      find.byKey(const ValueKey('green_grid_cell_2026_11_15')),
      findsNothing,
    );
  });

  testWidgets(
      'shows year dropdown with multiple years when startDate is in 2026 and current day is in 2027',
      (tester) async {
    final startDate = DateTime(2026, 10, 14);
    final simulated2027Day = DateTime(2027, 3, 20);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GreenGrid(
            entries: const [],
            startDate: startDate,
            currentDate: simulated2027Day,
          ),
        ),
      ),
    );

    // Dropdown at the top of the grid exists
    final yearSelector = find.byKey(const Key('green_grid_year_selector'));
    expect(yearSelector, findsOneWidget);

    // Tap dropdown to open options
    await tester.tap(yearSelector);
    await tester.pumpAndSettle();

    // Dropdown displays multiple years: 2026 and 2027
    expect(find.widgetWithText(DropdownMenuItem<int>, '2026'), findsOneWidget);
    expect(find.widgetWithText(DropdownMenuItem<int>, '2027'), findsWidgets);

    // Select 2026
    await tester.tap(find.widgetWithText(DropdownMenuItem<int>, '2026'));
    await tester.pumpAndSettle();

    // Now in 2026 view:
    // Oct 14, 2026 should be present
    expect(
      find.byKey(const ValueKey('green_grid_cell_2026_10_14')),
      findsOneWidget,
    );
    // Days prior to Oct 14 (e.g. Oct 12) should NOT exist
    expect(
      find.byKey(const ValueKey('green_grid_cell_2026_10_12')),
      findsNothing,
    );
  });
}
