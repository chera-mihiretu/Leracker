import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/presentation/task_setup/task_draft.dart';
import 'package:progress_tracker/features/tasks/presentation/task_setup/task_setup_flow.dart';

void main() {
  testWidgets('walks through all 6 pages and creates the task', (tester) async {
    TaskDraft? created;
    await tester.pumpWidget(MaterialApp(
      home: TaskSetupFlow(onCreated: (d) => created = d),
    ));
    await tester.pump(const Duration(milliseconds: 600));

    // Page 1: tap a preset chip, let it type itself.
    await tester.tap(find.text('Workout'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Workout'), findsWidgets);

    Future<void> next() async {
      await tester.tap(find.text('Continue'));
      await tester.pump(const Duration(milliseconds: 700));
    }

    await next(); // → page 2
    await tester.tap(find.text('Weekdays'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Weekly'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Every Monday'), findsOneWidget);
    await tester.tap(find.text('Monthly'));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.ensureVisible(find.text('15'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('15'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Monthly on the 15th'), findsOneWidget);
    await next(); // → page 3
    await tester.tap(find.text('Evening'));
    await tester.pump(const Duration(milliseconds: 600));
    await next(); // → page 4
    await tester.tap(find.text('3'));
    await tester.pump(const Duration(milliseconds: 600));
    await next(); // → page 5
    await next(); // → page 6

    await tester.tap(find.text('Create habit and start grid'));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(created, isNotNull);
    expect(created!.name, 'Workout');
    expect(created!.frequency, Frequency.monthly);
    expect(created!.monthDay, 15);
    expect(created!.timeLabel, '19:00');
    expect(created!.nudges, 3);

    // Let periodic timers (bell loop etc.) be torn down.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });

  test('isDueOn handles weekly, monthly and end of month', () {
    final d = TaskDraft()
      ..frequency = Frequency.weekly
      ..weekDay = 2; // Wednesday
    expect(d.isDueOn(DateTime(2026, 11, 18)), isTrue); // Wed
    expect(d.isDueOn(DateTime(2026, 11, 19)), isFalse);

    d
      ..frequency = Frequency.monthly
      ..monthDay = kEndOfMonth;
    expect(d.isDueOn(DateTime(2026, 2, 28)), isTrue);
    expect(d.isDueOn(DateTime(2026, 11, 30)), isTrue);
    expect(d.isDueOn(DateTime(2026, 11, 29)), isFalse);

    d.monthDay = 31; // falls back to the last day in short months
    expect(d.isDueOn(DateTime(2026, 4, 30)), isTrue);
    expect(d.isDueOn(DateTime(2026, 1, 31)), isTrue);

    expect(TaskDraft.ordinal(1), '1st');
    expect(TaskDraft.ordinal(12), '12th');
    expect(TaskDraft.ordinal(23), '23rd');
  });
}
