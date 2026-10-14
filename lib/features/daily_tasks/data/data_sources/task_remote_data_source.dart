import '../models/task_model.dart';

/// Contract for remote data access (REST API, Firebase, etc.).
abstract class TaskRemoteDataSource {
  /// Fetch tasks for a specific date from the remote server.
  Future<List<TaskModel>> getTasks(DateTime date);

  /// Sync a task to the remote server.
  Future<TaskModel> syncTask(TaskModel task);

  /// Fetch completion history from the remote server.
  Future<List<Map<String, dynamic>>> getCompletionHistory({
    required DateTime startDate,
    required DateTime endDate,
  });
}
