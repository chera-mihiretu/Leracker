import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/data/models/task_model.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entity.dart';

void main() {
  group('TaskModel', () {
    final now = DateTime.parse('2026-01-01T12:00:00.000Z');
    final testModel = TaskModel(
      id: 't1',
      userId: 'u1',
      name: 'Exercise',
      frequency: 'daily',
      createdAt: now,
      archived: false,
    );

    test('is a subclass of TaskEntity', () {
      expect(testModel, isA<TaskEntity>());
    });

    test('fromJson deserializes json map correctly', () {
      final json = {
        'id': 't1',
        'user_id': 'u1',
        'name': 'Exercise',
        'frequency_type': 'weekly',
        'days_of_week': [6],
        'monthly_rule': 'end',
        'start_time': '07:30:00',
        'reminder_count': 2,
        'grid_color': '#8B5CF6',
        'include_in_morning_review': false,
        'created_at': '2026-01-01T12:00:00.000Z',
        'archived': false,
      };

      final result = TaskModel.fromJson(json);

      expect(result.id, 't1');
      expect(result.name, 'Exercise');
      expect(result.frequencyType, 'weekly');
      expect(result.daysOfWeek, [6]);
      expect(result.monthlyRule, 'end');
      expect(result.startTime, '07:30:00');
      expect(result.reminderCount, 2);
      expect(result.gridColor, '#8B5CF6');
      expect(result.includeInMorningReview, false);
      expect(result.createdAt, now);
      expect(result.archived, false);
      expect(result.isUploaded, true);

      final unuploadedJson = Map<String, dynamic>.from(json);
      unuploadedJson['is_uploaded'] = false;
      final unuploadedModel = TaskModel.fromJson(unuploadedJson);
      expect(unuploadedModel.isUploaded, false);
    });

    test('toJson serializes model to json map correctly', () {
      final fullModel = TaskModel(
        id: 't1',
        userId: 'u1',
        name: 'Exercise',
        frequencyType: 'daily',
        daysOfWeek: const [1, 2, 3, 4, 5],
        monthlyRule: 'start',
        startTime: '08:00:00',
        reminderCount: 3,
        gridColor: '#10B981',
        includeInMorningReview: true,
        createdAt: now,
        archived: false,
      );

      final result = fullModel.toJson();

      expect(result['id'], 't1');
      expect(result['user_id'], 'u1');
      expect(result['name'], 'Exercise');
      expect(result['frequency_type'], 'daily');
      expect(result['days_of_week'], [1, 2, 3, 4, 5]);
      expect(result['monthly_rule'], 'start');
      expect(result['start_time'], '08:00:00');
      expect(result['reminder_count'], 3);
      expect(result['grid_color'], '#10B981');
      expect(result['include_in_morning_review'], true);
      expect(result['archived'], false);
    });

    test('fromEntity converts TaskEntity to TaskModel', () {
      final entity = TaskEntity(
        id: 't2',
        userId: 'u2',
        name: 'Meditate',
        createdAt: now,
      );

      final model = TaskModel.fromEntity(entity);

      expect(model.id, 't2');
      expect(model.name, 'Meditate');
    });
  });
}

