import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/exceptions.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/core/network/network_info.dart';
import 'package:progress_tracker/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:progress_tracker/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:progress_tracker/features/tasks/data/models/task_entry_model.dart';
import 'package:progress_tracker/features/tasks/data/models/task_model.dart';
import 'package:progress_tracker/features/tasks/data/repositories/task_repository_impl.dart';

class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}
class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockTaskRemoteDataSource mockRemoteDataSource;
  late MockTaskLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late TaskRepositoryImpl repository;

  final now = DateTime.now();
  final testTaskModel = TaskModel(
    id: 't1',
    userId: 'u1',
    name: 'Task 1',
    createdAt: now,
  );
  final testEntryModel = TaskEntryModel(
    id: 'e1',
    taskId: 't1',
    userId: 'u1',
    entryDate: now,
    status: 'done',
    answeredAt: now,
  );

  setUpAll(() {
    registerFallbackValue(testTaskModel);
    registerFallbackValue(testEntryModel);
  });

  setUp(() {
    mockRemoteDataSource = MockTaskRemoteDataSource();
    mockLocalDataSource = MockTaskLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = TaskRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getTasks', () {
    test('when online: fetches remote, caches locally, and returns list', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getTasks())
          .thenAnswer((_) async => [testTaskModel]);
      when(() => mockLocalDataSource.saveTasks(any()))
          .thenAnswer((_) async {});

      final result = await repository.getTasks();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), equals([testTaskModel]));
      verify(() => mockLocalDataSource.saveTasks([testTaskModel])).called(1);
    });

    test('when online but remote fails: falls back to local cache', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getTasks())
          .thenThrow(const ServerException(message: 'Remote error'));
      when(() => mockLocalDataSource.getTasks())
          .thenAnswer((_) async => [testTaskModel]);

      final result = await repository.getTasks();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), equals([testTaskModel]));
    });

    test('when offline: returns local cached tasks', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getTasks())
          .thenAnswer((_) async => [testTaskModel]);

      final result = await repository.getTasks();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), equals([testTaskModel]));
      verifyZeroInteractions(mockRemoteDataSource);
    });
  });

  group('addTask', () {
    test('when online: creates remotely and saves locally with isUploaded: true', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.addTask(
            name: any(named: 'name'),
            frequencyType: any(named: 'frequencyType'),
            daysOfWeek: any(named: 'daysOfWeek'),
            monthlyRule: any(named: 'monthlyRule'),
            startTime: any(named: 'startTime'),
            reminderCount: any(named: 'reminderCount'),
            gridColor: any(named: 'gridColor'),
            includeInMorningReview: any(named: 'includeInMorningReview'),
          )).thenAnswer((_) async => testTaskModel);
      when(() => mockLocalDataSource.saveTask(any()))
          .thenAnswer((_) async {});

      final result = await repository.addTask(name: 'Run');

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => testTaskModel).id, testTaskModel.id);
      expect(result.getOrElse((_) => testTaskModel).isUploaded, isTrue);
      verify(() => mockLocalDataSource.saveTask(testTaskModel.copyWith(isUploaded: true))).called(1);
    });

    test('when offline: creates optimistic local task marked with isUploaded: false and saves locally', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveTask(any()))
          .thenAnswer((_) async {});

      final result = await repository.addTask(name: 'Run');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be right'),
        (task) {
          expect(task.name, 'Run');
          expect(task.isUploaded, isFalse);
        },
      );
      verifyZeroInteractions(mockRemoteDataSource);
    });

    test('returns ServerFailure on ServerException', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.addTask(
            name: any(named: 'name'),
            frequencyType: any(named: 'frequencyType'),
            daysOfWeek: any(named: 'daysOfWeek'),
            monthlyRule: any(named: 'monthlyRule'),
            startTime: any(named: 'startTime'),
            reminderCount: any(named: 'reminderCount'),
            gridColor: any(named: 'gridColor'),
            includeInMorningReview: any(named: 'includeInMorningReview'),
          )).thenThrow(const ServerException(message: 'Creation failed'));

      final result = await repository.addTask(name: 'Run');

      expect(result, const Left(ServerFailure(message: 'Creation failed')));
    });
  });

  group('archiveTask', () {
    test('archives remotely if online and archives locally', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.archiveTask('t1')).thenAnswer((_) async {});
      when(() => mockLocalDataSource.archiveTask('t1')).thenAnswer((_) async {});

      final result = await repository.archiveTask('t1');

      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.archiveTask('t1')).called(1);
      verify(() => mockLocalDataSource.archiveTask('t1')).called(1);
    });
  });

  group('recordTaskEntry', () {
    test('when online: records remotely and saves locally', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.recordTaskEntry(
            taskId: 't1',
            entryDate: now,
            status: 'done',
          )).thenAnswer((_) async => testEntryModel);
      when(() => mockLocalDataSource.saveTaskEntry(any())).thenAnswer((_) async {});

      final result = await repository.recordTaskEntry(
        taskId: 't1',
        entryDate: now,
        status: 'done',
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => testEntryModel).id, testEntryModel.id);
    });

    test('when offline: creates local optimistic entry', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.saveTaskEntry(any())).thenAnswer((_) async {});

      final result = await repository.recordTaskEntry(
        taskId: 't1',
        entryDate: now,
        status: 'missed',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be right'),
        (entry) => expect(entry.status, 'missed'),
      );
    });
  });

  group('getAllTaskEntries', () {
    test('when online: gets remote entries, caches them and groups by taskId', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getAllTaskEntries())
          .thenAnswer((_) async => [testEntryModel]);
      when(() => mockLocalDataSource.saveTaskEntries(any())).thenAnswer((_) async {});

      final result = await repository.getAllTaskEntries();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be right'),
        (map) => expect(map['t1']?.length, 1),
      );
    });

    test('when offline: reads from local cache', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockLocalDataSource.getTaskEntries())
          .thenAnswer((_) async => {'t1': [testEntryModel]});

      final result = await repository.getAllTaskEntries();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('should be right'),
        (map) => expect(map['t1']?.length, 1),
      );
    });
  });

  group('syncUnsyncedTasks', () {
    test('when offline: returns empty list and does not call remote', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.syncUnsyncedTasks();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), isEmpty);
      verifyZeroInteractions(mockRemoteDataSource);
    });

    test('when online but no unsynced tasks: returns empty list', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getUnsyncedTasks()).thenAnswer((_) async => []);

      final result = await repository.syncUnsyncedTasks();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), isEmpty);
      verifyZeroInteractions(mockRemoteDataSource);
    });

    test('when online with unsynced tasks: uploads them, marks as uploaded, removes temp local task, avoids duplicate', () async {
      final localUnsyncedTask = TaskModel(
        id: 'local_123',
        userId: 'local_user',
        name: 'Offline Habit',
        createdAt: now,
        isUploaded: false,
      );
      final remoteCreatedTask = TaskModel(
        id: 'remote_999',
        userId: 'u1',
        name: 'Offline Habit',
        createdAt: now,
        isUploaded: true,
      );

      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getUnsyncedTasks())
          .thenAnswer((_) async => [localUnsyncedTask]);
      when(() => mockRemoteDataSource.addTask(
            name: 'Offline Habit',
            frequencyType: any(named: 'frequencyType'),
            daysOfWeek: any(named: 'daysOfWeek'),
            monthlyRule: any(named: 'monthlyRule'),
            startTime: any(named: 'startTime'),
            reminderCount: any(named: 'reminderCount'),
            gridColor: any(named: 'gridColor'),
            includeInMorningReview: any(named: 'includeInMorningReview'),
          )).thenAnswer((_) async => remoteCreatedTask);
      when(() => mockLocalDataSource.deleteTask('local_123')).thenAnswer((_) async {});
      when(() => mockLocalDataSource.saveTask(any())).thenAnswer((_) async {});
      when(() => mockLocalDataSource.updateEntryTaskId(
            oldTaskId: 'local_123',
            newTaskId: 'remote_999',
          )).thenAnswer((_) async {});

      final result = await repository.syncUnsyncedTasks();

      expect(result.isRight(), isTrue);
      final uploaded = result.getOrElse((_) => []);
      expect(uploaded.length, 1);
      expect(uploaded.first.id, 'remote_999');
      expect(uploaded.first.isUploaded, isTrue);

      verify(() => mockRemoteDataSource.addTask(
            name: 'Offline Habit',
            frequencyType: any(named: 'frequencyType'),
            daysOfWeek: any(named: 'daysOfWeek'),
            monthlyRule: any(named: 'monthlyRule'),
            startTime: any(named: 'startTime'),
            reminderCount: any(named: 'reminderCount'),
            gridColor: any(named: 'gridColor'),
            includeInMorningReview: any(named: 'includeInMorningReview'),
          )).called(1);
      verify(() => mockLocalDataSource.deleteTask('local_123')).called(1);
      verify(() => mockLocalDataSource.saveTask(remoteCreatedTask.copyWith(isUploaded: true))).called(1);
    });

    test('when one task fails to upload: leaves it unsynced and continues', () async {
      final taskFail = TaskModel(
        id: 'local_fail',
        userId: 'local_user',
        name: 'Fail Habit',
        createdAt: now,
        isUploaded: false,
      );
      final taskSuccess = TaskModel(
        id: 'local_ok',
        userId: 'local_user',
        name: 'OK Habit',
        createdAt: now,
        isUploaded: false,
      );
      final remoteSuccess = TaskModel(
        id: 'remote_ok',
        userId: 'u1',
        name: 'OK Habit',
        createdAt: now,
        isUploaded: true,
      );

      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockLocalDataSource.getUnsyncedTasks())
          .thenAnswer((_) async => [taskFail, taskSuccess]);
      when(() => mockRemoteDataSource.addTask(
            name: 'Fail Habit',
            frequencyType: any(named: 'frequencyType'),
            daysOfWeek: any(named: 'daysOfWeek'),
            monthlyRule: any(named: 'monthlyRule'),
            startTime: any(named: 'startTime'),
            reminderCount: any(named: 'reminderCount'),
            gridColor: any(named: 'gridColor'),
            includeInMorningReview: any(named: 'includeInMorningReview'),
          )).thenThrow(const ServerException(message: 'Network drop'));
      when(() => mockRemoteDataSource.addTask(
            name: 'OK Habit',
            frequencyType: any(named: 'frequencyType'),
            daysOfWeek: any(named: 'daysOfWeek'),
            monthlyRule: any(named: 'monthlyRule'),
            startTime: any(named: 'startTime'),
            reminderCount: any(named: 'reminderCount'),
            gridColor: any(named: 'gridColor'),
            includeInMorningReview: any(named: 'includeInMorningReview'),
          )).thenAnswer((_) async => remoteSuccess);
      when(() => mockLocalDataSource.deleteTask('local_ok')).thenAnswer((_) async {});
      when(() => mockLocalDataSource.saveTask(any())).thenAnswer((_) async {});
      when(() => mockLocalDataSource.updateEntryTaskId(
            oldTaskId: 'local_ok',
            newTaskId: 'remote_ok',
          )).thenAnswer((_) async {});

      final result = await repository.syncUnsyncedTasks();

      expect(result.isRight(), isTrue);
      final uploaded = result.getOrElse((_) => []);
      expect(uploaded.length, 1);
      expect(uploaded.first.id, 'remote_ok');

      // Only successful task's local temp record was deleted
      verifyNever(() => mockLocalDataSource.deleteTask('local_fail'));
      verify(() => mockLocalDataSource.deleteTask('local_ok')).called(1);
    });
  });
}
