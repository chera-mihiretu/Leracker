import '../models/task_entry_model.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getTasks();
  Future<void> saveTasks(List<TaskModel> tasks);
  Future<void> saveTask(TaskModel task);
  Future<void> archiveTask(String taskId);
  Future<void> deleteTask(String taskId);
  Future<List<TaskModel>> getUnsyncedTasks();

  Future<Map<String, List<TaskEntryModel>>> getTaskEntries();
  Future<List<TaskEntryModel>> getEntriesForTask(String taskId);
  Future<void> saveTaskEntry(TaskEntryModel entry);
  Future<void> saveTaskEntries(List<TaskEntryModel> entries);
  Future<void> updateEntryTaskId({
    required String oldTaskId,
    required String newTaskId,
  });
}

class InMemoryTaskLocalDataSource implements TaskLocalDataSource {
  final List<TaskModel> _tasks = [];
  final List<TaskEntryModel> _entries = [];

  @override
  Future<List<TaskModel>> getTasks() async {
    return _tasks.where((t) => !t.archived).toList();
  }

  @override
  Future<void> saveTasks(List<TaskModel> tasks) async {
    for (final task in tasks) {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index >= 0) {
        _tasks[index] = task;
      } else {
        _tasks.add(task);
      }
    }
  }

  @override
  Future<void> saveTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index >= 0) {
      _tasks[index] = task;
    } else {
      _tasks.add(task);
    }
  }

  @override
  Future<void> archiveTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index >= 0) {
      final t = _tasks[index];
      _tasks[index] = TaskModel(
        id: t.id,
        userId: t.userId,
        name: t.name,
        frequency: t.frequency,
        createdAt: t.createdAt,
        archived: true,
        isUploaded: t.isUploaded,
      );
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
  }

  @override
  Future<List<TaskModel>> getUnsyncedTasks() async {
    return _tasks.where((t) => !t.isUploaded && !t.archived).toList();
  }

  @override
  Future<Map<String, List<TaskEntryModel>>> getTaskEntries() async {
    final map = <String, List<TaskEntryModel>>{};
    for (final entry in _entries) {
      map.putIfAbsent(entry.taskId, () => []).add(entry);
    }
    return map;
  }

  @override
  Future<List<TaskEntryModel>> getEntriesForTask(String taskId) async {
    return _entries.where((e) => e.taskId == taskId).toList();
  }

  @override
  Future<void> saveTaskEntry(TaskEntryModel entry) async {
    final index = _entries.indexWhere(
      (e) =>
          e.taskId == entry.taskId &&
          e.entryDate.year == entry.entryDate.year &&
          e.entryDate.month == entry.entryDate.month &&
          e.entryDate.day == entry.entryDate.day,
    );
    if (index >= 0) {
      _entries[index] = entry;
    } else {
      _entries.add(entry);
    }
  }

  @override
  Future<void> saveTaskEntries(List<TaskEntryModel> entries) async {
    for (final entry in entries) {
      await saveTaskEntry(entry);
    }
  }

  @override
  Future<void> updateEntryTaskId({
    required String oldTaskId,
    required String newTaskId,
  }) async {
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].taskId == oldTaskId) {
        _entries[i] = TaskEntryModel(
          id: _entries[i].id,
          taskId: newTaskId,
          userId: _entries[i].userId,
          entryDate: _entries[i].entryDate,
          status: _entries[i].status,
          answeredAt: _entries[i].answeredAt,
        );
      }
    }
  }
}

