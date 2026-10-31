import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:progress_tracker/features/tasks/data/models/task_entry_model.dart';
import 'package:progress_tracker/features/tasks/data/models/task_model.dart';

void main() {
  late InMemoryTaskLocalDataSource dataSource;

  setUp(() {
    dataSource = InMemoryTaskLocalDataSource();
  });

  final now = DateTime.now();
  final task1 = TaskModel(
    id: 't1',
    userId: 'u1',
    name: 'Task 1',
    createdAt: now,
  );
  final task2 = TaskModel(
    id: 't2',
    userId: 'u1',
    name: 'Task 2',
    createdAt: now,
  );

  group('Tasks storage', () {
    test('saveTask and getTasks return unarchived tasks', () async {
      await dataSource.saveTask(task1);
      await dataSource.saveTask(task2);

      final tasks = await dataSource.getTasks();
      expect(tasks.length, 2);
    });

    test('archiveTask hides task from getTasks', () async {
      await dataSource.saveTask(task1);
      await dataSource.archiveTask('t1');

      final tasks = await dataSource.getTasks();
      expect(tasks, isEmpty);
    });

    test('saveTasks batch updates/adds tasks', () async {
      await dataSource.saveTasks([task1, task2]);
      final tasks = await dataSource.getTasks();
      expect(tasks.length, 2);
    });
  });

  group('TaskEntries storage', () {
    final entry1 = TaskEntryModel(
      id: 'e1',
      taskId: 't1',
      userId: 'u1',
      entryDate: DateTime(2026, 1, 1),
      status: 'done',
      answeredAt: now,
    );
    final entry2 = TaskEntryModel(
      id: 'e2',
      taskId: 't1',
      userId: 'u1',
      entryDate: DateTime(2026, 1, 2),
      status: 'missed',
      answeredAt: now,
    );

    test('saveTaskEntry and getEntriesForTask', () async {
      await dataSource.saveTaskEntry(entry1);
      await dataSource.saveTaskEntry(entry2);

      final entries = await dataSource.getEntriesForTask('t1');
      expect(entries.length, 2);
    });

    test('saveTaskEntry replaces existing entry for same date', () async {
      await dataSource.saveTaskEntry(entry1);
      final updatedEntry = TaskEntryModel(
        id: 'e1_updated',
        taskId: 't1',
        userId: 'u1',
        entryDate: DateTime(2026, 1, 1),
        status: 'missed',
        answeredAt: now,
      );
      await dataSource.saveTaskEntry(updatedEntry);

      final entries = await dataSource.getEntriesForTask('t1');
      expect(entries.length, 1);
      expect(entries.first.status, 'missed');
    });

    test('getTaskEntries groups entries by taskId', () async {
      await dataSource.saveTaskEntries([entry1, entry2]);

      final grouped = await dataSource.getTaskEntries();
      expect(grouped['t1']?.length, 2);
    });
  });
}

