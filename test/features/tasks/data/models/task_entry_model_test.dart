import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/data/models/task_entry_model.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entry_entity.dart';

void main() {
  group('TaskEntryModel', () {
    final entryDate = DateTime(2026, 1, 5);
    final answeredAt = DateTime.parse('2026-01-05T08:30:00.000Z');
    final testModel = TaskEntryModel(
      id: 'e1',
      taskId: 't1',
      userId: 'u1',
      entryDate: entryDate,
      status: 'done',
      answeredAt: answeredAt,
    );

    test('is a subclass of TaskEntryEntity', () {
      expect(testModel, isA<TaskEntryEntity>());
    });

    test('fromJson deserializes json map correctly', () {
      final json = {
        'id': 'e1',
        'task_id': 't1',
        'user_id': 'u1',
        'entry_date': '2026-01-05',
        'status': 'done',
        'answered_at': '2026-01-05T08:30:00.000Z',
      };

      final result = TaskEntryModel.fromJson(json);

      expect(result.id, 'e1');
      expect(result.taskId, 't1');
      expect(result.status, 'done');
      expect(result.entryDate.year, 2026);
      expect(result.entryDate.month, 1);
      expect(result.entryDate.day, 5);
    });

    test('toJson formats entry_date as YYYY-MM-DD', () {
      final json = testModel.toJson();

      expect(json['entry_date'], '2026-01-05');
      expect(json['status'], 'done');
      expect(json['task_id'], 't1');
    });

    test('fromEntity converts TaskEntryEntity to TaskEntryModel', () {
      final entity = TaskEntryEntity(
        id: 'e2',
        taskId: 't2',
        userId: 'u2',
        entryDate: entryDate,
        status: 'missed',
        answeredAt: answeredAt,
      );

      final model = TaskEntryModel.fromEntity(entity);

      expect(model.id, 'e2');
      expect(model.status, 'missed');
    });
  });
}

