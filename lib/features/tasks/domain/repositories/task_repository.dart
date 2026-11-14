import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../entities/task_entry_entity.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<TaskEntity>>> getTasks();
  Future<Either<Failure, TaskEntity>> addTask({
    required String name,
    String frequencyType = 'daily',
    String? frequency,
    List<int> daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    String? monthlyRule,
    String? startTime,
    int reminderCount = 1,
    String gridColor = '#22C55E',
    bool includeInMorningReview = true,
  });
  Future<Either<Failure, void>> archiveTask(String taskId);

  Future<Either<Failure, List<TaskEntryEntity>>> getTaskEntries(String taskId);
  Future<Either<Failure, TaskEntryEntity>> recordTaskEntry({
    required String taskId,
    required DateTime entryDate,
    required String status,
  });
  Future<Either<Failure, Map<String, List<TaskEntryEntity>>>> getAllTaskEntries();

  /// Synchronizes local tasks that have not yet been uploaded to remote.
  /// Skips already uploaded tasks to prevent duplicate uploads.
  Future<Either<Failure, List<TaskEntity>>> syncUnsyncedTasks();
}

