import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_entry_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../datasources/task_remote_data_source.dart';
import '../models/task_entry_model.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TaskEntity>>> getTasks() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteTasks = await remoteDataSource.getTasks();
          await localDataSource.saveTasks(remoteTasks);
          return Right(remoteTasks);
        } catch (_) {
          final localTasks = await localDataSource.getTasks();
          return Right(localTasks);
        }
      } else {
        final localTasks = await localDataSource.getTasks();
        return Right(localTasks);
      }
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
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
  }) async {
    final effectiveFreq = frequency ?? frequencyType;
    try {
      if (await networkInfo.isConnected) {
        final remoteTask = await remoteDataSource.addTask(
          name: name,
          frequencyType: effectiveFreq,
          daysOfWeek: daysOfWeek,
          monthlyRule: monthlyRule,
          startTime: startTime,
          reminderCount: reminderCount,
          gridColor: gridColor,
          includeInMorningReview: includeInMorningReview,
        );
        final markedTask = remoteTask.copyWith(isUploaded: true);
        await localDataSource.saveTask(markedTask);
        return Right(markedTask);
      } else {
        // Create local optimistic task marked as not uploaded
        final localTask = TaskModel(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'local_user',
          name: name,
          frequencyType: effectiveFreq,
          daysOfWeek: daysOfWeek,
          monthlyRule: monthlyRule,
          startTime: startTime,
          reminderCount: reminderCount,
          gridColor: gridColor,
          includeInMorningReview: includeInMorningReview,
          createdAt: DateTime.now(),
          isUploaded: false,
        );
        await localDataSource.saveTask(localTask);
        return Right(localTask);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> archiveTask(String taskId) async {
    try {
      if (await networkInfo.isConnected) {
        await remoteDataSource.archiveTask(taskId);
      }
      await localDataSource.archiveTask(taskId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntryEntity>>> getTaskEntries(
    String taskId,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final entries = await remoteDataSource.getTaskEntries(taskId);
          await localDataSource.saveTaskEntries(entries);
          return Right(entries);
        } catch (_) {
          final localEntries = await localDataSource.getEntriesForTask(taskId);
          return Right(localEntries);
        }
      } else {
        final localEntries = await localDataSource.getEntriesForTask(taskId);
        return Right(localEntries);
      }
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<TaskEntryEntity>>>>
  getAllTaskEntries() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final entries = await remoteDataSource.getAllTaskEntries();
          await localDataSource.saveTaskEntries(entries);
          final grouped = <String, List<TaskEntryEntity>>{};
          for (final entry in entries) {
            grouped.putIfAbsent(entry.taskId, () => []).add(entry);
          }
          return Right(grouped);
        } catch (_) {
          final localMap = await localDataSource.getTaskEntries();
          return Right(localMap);
        }
      } else {
        final localMap = await localDataSource.getTaskEntries();
        return Right(localMap);
      }
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TaskEntryEntity>> recordTaskEntry({
    required String taskId,
    required DateTime entryDate,
    required String status,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteEntry = await remoteDataSource.recordTaskEntry(
          taskId: taskId,
          entryDate: entryDate,
          status: status,
        );
        await localDataSource.saveTaskEntry(remoteEntry);
        return Right(remoteEntry);
      } else {
        final localEntry = TaskEntryModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          taskId: taskId,
          userId: 'local_user',
          entryDate: entryDate,
          status: status,
          answeredAt: DateTime.now(),
        );
        await localDataSource.saveTaskEntry(localEntry);
        return Right(localEntry);
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TaskEntity>>> syncUnsyncedTasks() async {
    try {
      if (!await networkInfo.isConnected) {
        return const Right([]);
      }

      final unsyncedTasks = await localDataSource.getUnsyncedTasks();
      if (unsyncedTasks.isEmpty) {
        return const Right([]);
      }

      final uploadedTasks = <TaskEntity>[];
      for (final localTask in unsyncedTasks) {
        try {
          final remoteTask = await remoteDataSource.addTask(
            name: localTask.name,
            frequencyType: localTask.frequencyType,
            daysOfWeek: localTask.daysOfWeek,
            monthlyRule: localTask.monthlyRule,
            startTime: localTask.startTime,
            reminderCount: localTask.reminderCount,
            gridColor: localTask.gridColor,
            includeInMorningReview: localTask.includeInMorningReview,
          );

          // Mark as uploaded, remove temporary local task and save remote task
          final markedTask = remoteTask.copyWith(isUploaded: true);
          await localDataSource.deleteTask(localTask.id);
          await localDataSource.saveTask(markedTask);
          await localDataSource.updateEntryTaskId(
            oldTaskId: localTask.id,
            newTaskId: markedTask.id,
          );
          uploadedTasks.add(markedTask);
        } catch (_) {
          // Leave unsynced for next sync retry
        }
      }

      return Right(uploadedTasks);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
