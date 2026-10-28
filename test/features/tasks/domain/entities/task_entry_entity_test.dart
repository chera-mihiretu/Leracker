import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entry_entity.dart';

void main() {
  group('TaskEntryEntity', () {
    final date = DateTime(2026, 1, 1);
    final entryDone = TaskEntryEntity(
      id: 'e1',
      taskId: 't1',
      userId: 'u1',
      entryDate: date,
      status: 'done',
      answeredAt: date,
    );
    final entryMissed = TaskEntryEntity(
      id: 'e2',
      taskId: 't1',
      userId: 'u1',
      entryDate: date,
      status: 'missed',
      answeredAt: date,
    );

    test('isDone and isMissed return expected booleans', () {
      expect(entryDone.isDone, isTrue);
      expect(entryDone.isMissed, isFalse);

      expect(entryMissed.isDone, isFalse);
      expect(entryMissed.isMissed, isTrue);
    });

    test('supports value equality', () {
      final copy = TaskEntryEntity(
        id: 'e1',
        taskId: 't1',
        userId: 'u1',
        entryDate: date,
        status: 'done',
        answeredAt: date,
      );
      expect(entryDone, equals(copy));
    });
  });
}

