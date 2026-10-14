import '../models/task_model.dart';

/// Contract for local persistence (SQLite, Hive, SharedPreferences, etc.).
abstract class TaskLocalDataSource {
  /// Get all cached tasks for a given date.
  Future<List<TaskModel>> getTasks(DateTime date);

  /// Insert or update a task in local storage.
  Future<TaskModel> saveTask(TaskModel task);

  /// Toggle completion status and return the updated task.
  Future<TaskModel> toggleTaskCompletion(String taskId);

  /// Delete a task from local storage.
  Future<void> deleteTask(String taskId);

  /// Get daily logs between two dates from cache.
  Future<List<Map<String, dynamic>>> getCompletionHistory({
    required DateTime startDate,
    required DateTime endDate,
  });
}
