import '../../domain/entities/task.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/task_repository.dart';
import '../data_sources/task_local_data_source.dart';
import '../models/task_model.dart';
import '../models/daily_log_model.dart';

/// Concrete implementation of [TaskRepository].
///
/// Currently backed by local storage only.
/// Extend with remote data source and network checks as needed.
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Task>> getTasks(DateTime date) async {
    final models = await localDataSource.getTasks(date);
    return models;
  }

  @override
  Future<Task> addTask(Task task) async {
    final model = TaskModel.fromEntity(task);
    return await localDataSource.saveTask(model);
  }

  @override
  Future<Task> toggleTaskCompletion(String taskId) async {
    return await localDataSource.toggleTaskCompletion(taskId);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await localDataSource.deleteTask(taskId);
  }

  @override
  Future<List<DailyLog>> getCompletionHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final rawLogs = await localDataSource.getCompletionHistory(
      startDate: startDate,
      endDate: endDate,
    );
    return rawLogs.map((json) => DailyLogModel.fromJson(json)).toList();
  }
}
