import '../entities/task.dart';
import '../entities/daily_log.dart';

/// Abstract repository contract for the domain layer.
/// The data layer provides the concrete implementation.
abstract class TaskRepository {
  /// Get all tasks for a specific date.
  Future<List<Task>> getTasks(DateTime date);

  /// Add a new task.
  Future<Task> addTask(Task task);

  /// Toggle a task's completion status.
  Future<Task> toggleTaskCompletion(String taskId);

  /// Delete a task by id.
  Future<void> deleteTask(String taskId);

  /// Get completion history for a date range (for the contribution grid).
  Future<List<DailyLog>> getCompletionHistory({
    required DateTime startDate,
    required DateTime endDate,
  });
}
