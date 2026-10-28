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
    });
  });
}

