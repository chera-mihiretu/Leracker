import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entity.dart';

void main() {
  group('TaskEntity', () {
    final now = DateTime(2026, 1, 1);
    final task1 = TaskEntity(
      id: 't1',
      userId: 'u1',
      name: 'Read Book',
      createdAt: now,
    );
    final task2 = TaskEntity(
      id: 't1',
      userId: 'u1',
      name: 'Read Book',
      createdAt: now,
    );

    test('supports value equality', () {
      expect(task1, equals(task2));
    });

    test('copyWith creates new entity with updated fields', () {
      final updated = task1.copyWith(
        name: 'Read 20 pages',
        archived: true,
        frequencyType: 'weekly',
        daysOfWeek: [7],
        monthlyRule: 'start',
        startTime: '08:00',
        reminderCount: 2,
        gridColor: '#8B5CF6',
        includeInMorningReview: false,
      );

      expect(updated.name, 'Read 20 pages');
      expect(updated.archived, true);
      expect(updated.id, 't1');
      expect(updated.frequencyType, 'weekly');
      expect(updated.frequency, 'weekly');
      expect(updated.daysOfWeek, [7]);
      expect(updated.monthlyRule, 'start');
      expect(updated.startTime, '08:00');
      expect(updated.reminderCount, 2);
      expect(updated.gridColor, '#8B5CF6');
      expect(updated.includeInMorningReview, false);
      expect(updated.isUploaded, true);

      final unuploaded = task1.copyWith(isUploaded: false);
      expect(unuploaded.isUploaded, false);
    });

    test('isUploaded defaults to true', () {
      expect(task1.isUploaded, isTrue);
    });

    test('isDueOn daily correctly checks daysOfWeek (1=Mon ... 7=Sun)', () {
      final dailyTask = TaskEntity(
        id: 't-daily',
        userId: 'u1',
        name: 'Gym',
        createdAt: now,
        frequencyType: 'daily',
        daysOfWeek: const [1, 3, 5], // Mon, Wed, Fri
      );

      final monday = DateTime(2026, 11, 9); // weekday 1
      final tuesday = DateTime(2026, 11, 10); // weekday 2
      final wednesday = DateTime(2026, 11, 11); // weekday 3

      expect(dailyTask.isDueOn(monday), isTrue);
      expect(dailyTask.isDueOn(tuesday), isFalse);
      expect(dailyTask.isDueOn(wednesday), isTrue);
    });

    test('isDueOn weekly checks chosen weekday', () {
      final weeklyTask = TaskEntity(
        id: 't-weekly',
        userId: 'u1',
        name: 'Sunday Long Run',
        createdAt: now,
        frequencyType: 'weekly',
        daysOfWeek: const [7], // Sunday
      );

      final sunday = DateTime(2026, 11, 15); // weekday 7
      final saturday = DateTime(2026, 11, 14); // weekday 6

      expect(weeklyTask.isDueOn(sunday), isTrue);
      expect(weeklyTask.isDueOn(saturday), isFalse);
    });

    test('isDueOn monthly evaluates start, end, and specific day rules', () {
      final monthEndTask = TaskEntity(
        id: 't-end',
        userId: 'u1',
        name: 'Month End Report',
        createdAt: now,
        frequencyType: 'monthly',
        monthlyRule: 'end',
      );

      expect(monthEndTask.isDueOn(DateTime(2026, 2, 28)), isTrue);
      expect(monthEndTask.isDueOn(DateTime(2026, 2, 27)), isFalse);
      expect(monthEndTask.isDueOn(DateTime(2026, 4, 30)), isTrue);
      expect(monthEndTask.isDueOn(DateTime(2026, 5, 31)), isTrue);

      final monthDayTask = TaskEntity(
        id: 't-day',
        userId: 'u1',
        name: 'Mid-Month Review',
        createdAt: now,
        frequencyType: 'monthly',
        monthlyRule: '15',
      );

      expect(monthDayTask.isDueOn(DateTime(2026, 11, 15)), isTrue);
      expect(monthDayTask.isDueOn(DateTime(2026, 11, 14)), isFalse);
    });
  });
}

