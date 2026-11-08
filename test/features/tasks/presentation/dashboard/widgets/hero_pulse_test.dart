import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dash_theme.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dashboard_store.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/task_item.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/hero_pulse.dart';

void main() {
  final today = dateOnly(DateTime.now());

  Widget buildWidget(DashboardStore store) {
    return MaterialApp(
      home: Scaffold(
        body: DashTheme(
          palette: DashPalette.dark,
          child: HeroPulse(store: store),
        ),
      ),
    );
  }

  testWidgets('HeroPulse renders "Nothing due today" when 0 tasks are due',
      (tester) async {
    final store = DashboardStore();
    await tester.pumpWidget(buildWidget(store));
    await tester.pumpAndSettle();

    expect(find.text('Nothing due today'), findsOneWidget);
    expect(find.text('0 of 0 done today'), findsOneWidget);
  });

  testWidgets('HeroPulse renders "All done for today" when all due tasks are done',
      (tester) async {
    final task = TaskItem(
      id: '1',
      name: 'Meditation',
      gridColor: const Color(0xFF22C55E),
      daysOfWeek: {today.weekday - 1},
      entries: {today: EntryStatus.done},
    );
    final store = DashboardStore(tasks: [task]);

    await tester.pumpWidget(buildWidget(store));
    await tester.pumpAndSettle();

    expect(find.text('All done for today'), findsOneWidget);
    expect(find.text('1 of 1 done today'), findsOneWidget);
  });

  testWidgets('HeroPulse renders "You\'re on track today" when ratio >= 0.5',
      (tester) async {
    final t1 = TaskItem(
      id: '1',
      name: 'Task 1',
      gridColor: const Color(0xFF22C55E),
      daysOfWeek: {today.weekday - 1},
      entries: {today: EntryStatus.done},
    );
    final t2 = TaskItem(
      id: '2',
      name: 'Task 2',
      gridColor: const Color(0xFF8B5CF6),
      daysOfWeek: {today.weekday - 1},
    );
    final store = DashboardStore(tasks: [t1, t2]);

    await tester.pumpWidget(buildWidget(store));
    await tester.pumpAndSettle();

    expect(find.text('You\'re on track today'), findsOneWidget);
    expect(find.text('1 of 2 done today'), findsOneWidget);
  });

  testWidgets('HeroPulse renders "Let\'s build momentum" when ratio < 0.5',
      (tester) async {
    final t1 = TaskItem(
      id: '1',
      name: 'Task 1',
      gridColor: const Color(0xFF22C55E),
      daysOfWeek: {today.weekday - 1},
    );
    final t2 = TaskItem(
      id: '2',
      name: 'Task 2',
      gridColor: const Color(0xFF8B5CF6),
      daysOfWeek: {today.weekday - 1},
    );
    final t3 = TaskItem(
      id: '3',
      name: 'Task 3',
      gridColor: const Color(0xFFF59E0B),
      daysOfWeek: {today.weekday - 1},
    );
    final store = DashboardStore(tasks: [t1, t2, t3]);

    await tester.pumpWidget(buildWidget(store));
    await tester.pumpAndSettle();

    expect(find.text('Let\'s build momentum'), findsOneWidget);
    expect(find.text('0 of 3 done today'), findsOneWidget);
  });
}

