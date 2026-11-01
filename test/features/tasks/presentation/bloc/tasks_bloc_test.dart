import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/core/usecases/usecase.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entity.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entry_entity.dart';
import 'package:progress_tracker/features/tasks/domain/usecases/add_task.dart';
import 'package:progress_tracker/features/tasks/domain/usecases/get_task_entries.dart';
import 'package:progress_tracker/features/tasks/domain/usecases/get_tasks.dart';
import 'package:progress_tracker/features/tasks/domain/usecases/record_task_entry.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_state.dart';

class MockGetTasks extends Mock implements GetTasks {}
class MockAddTask extends Mock implements AddTask {}
class MockGetTaskEntries extends Mock implements GetTaskEntries {}
class MockRecordTaskEntry extends Mock implements RecordTaskEntry {}

void main() {
  late MockGetTasks mockGetTasks;
  late MockAddTask mockAddTask;
  late MockGetTaskEntries mockGetTaskEntries;
  late MockRecordTaskEntry mockRecordTaskEntry;
  late TasksBloc tasksBloc;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const AddTaskParams(name: 'fallback'));
    registerFallbackValue(RecordTaskEntryParams(
      taskId: 't1',
      entryDate: DateTime.now(),
      status: 'done',
    ));
  });

  setUp(() {
    mockGetTasks = MockGetTasks();
    mockAddTask = MockAddTask();
    mockGetTaskEntries = MockGetTaskEntries();
    mockRecordTaskEntry = MockRecordTaskEntry();

    tasksBloc = TasksBloc(
      getTasks: mockGetTasks,
      addTask: mockAddTask,
      getTaskEntries: mockGetTaskEntries,
      recordTaskEntry: mockRecordTaskEntry,
    );
  });

  tearDown(() {
    tasksBloc.close();
  });

  final now = DateTime(2026, 1, 1);
  final testTask = TaskEntity(
    id: 't1',
    userId: 'u1',
    name: 'Read Book',
    createdAt: now,
  );
  final testEntry = TaskEntryEntity(
    id: 'e1',
    taskId: 't1',
    userId: 'u1',
    entryDate: now,
    status: 'done',
    answeredAt: now,
  );

  test('initial state is TasksInitial', () {
    expect(tasksBloc.state, const TasksInitial());
  });

  group('LoadTasksRequested', () {
    blocTest<TasksBloc, TasksState>(
      'emits [TasksLoading, TasksLoaded] when tasks and entries load successfully',
      build: () {
        when(() => mockGetTasks(any()))
            .thenAnswer((_) async => Right([testTask]));
        when(() => mockGetTaskEntries(any()))
            .thenAnswer((_) async => Right({'t1': [testEntry]}));
        return tasksBloc;
      },
      act: (bloc) => bloc.add(const LoadTasksRequested()),
      expect: () => [
        const TasksLoading(),
        TasksLoaded(
          tasks: [testTask],
          entriesByTaskId: {'t1': [testEntry]},
        ),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits [TasksLoading, TasksError] when getTasks fails',
      build: () {
        when(() => mockGetTasks(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Fetch failed')));
        when(() => mockGetTaskEntries(any()))
            .thenAnswer((_) async => const Right({}));
        return tasksBloc;
      },
      act: (bloc) => bloc.add(const LoadTasksRequested()),
      expect: () => [
        const TasksLoading(),
        const TasksError('Fetch failed'),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits [TasksLoading, TasksLoaded] with empty entries when getTaskEntries fails but getTasks succeeds',
      build: () {
        when(() => mockGetTasks(any()))
            .thenAnswer((_) async => Right([testTask]));
        when(() => mockGetTaskEntries(any()))
            .thenAnswer((_) async => const Left(CacheFailure(message: 'Entries failed')));
        return tasksBloc;
      },
      act: (bloc) => bloc.add(const LoadTasksRequested()),
      expect: () => [
        const TasksLoading(),
        TasksLoaded(
          tasks: [testTask],
          entriesByTaskId: const {},
        ),
      ],
    );
  });

  group('AddTaskSubmitted', () {
    blocTest<TasksBloc, TasksState>(
      'appends new task to TasksLoaded on success',
      build: () {
        when(() => mockAddTask(any()))
            .thenAnswer((_) async => Right(testTask));
        return tasksBloc;
      },
      seed: () => const TasksLoaded(tasks: [], entriesByTaskId: {}),
      act: (bloc) => bloc.add(const AddTaskSubmitted(name: 'Read Book')),
      expect: () => [
        TasksLoaded(
          tasks: [testTask],
          entriesByTaskId: const {},
        ),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits TasksError when addTask fails',
      build: () {
        when(() => mockAddTask(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to add')));
        return tasksBloc;
      },
      act: (bloc) => bloc.add(const AddTaskSubmitted(name: 'Read Book')),
      expect: () => [
        const TasksError('Failed to add'),
      ],
    );
  });

  group('RecordEntrySubmitted', () {
    blocTest<TasksBloc, TasksState>(
      'updates entry for taskId in TasksLoaded state',
      build: () {
        when(() => mockRecordTaskEntry(any()))
            .thenAnswer((_) async => Right(testEntry));
        return tasksBloc;
      },
      seed: () => TasksLoaded(
        tasks: [testTask],
        entriesByTaskId: const {},
      ),
      act: (bloc) => bloc.add(RecordEntrySubmitted(
        taskId: 't1',
        entryDate: now,
        status: 'done',
      )),
      expect: () => [
        TasksLoaded(
          tasks: [testTask],
          entriesByTaskId: {
            't1': [testEntry],
          },
        ),
      ],
    );

    blocTest<TasksBloc, TasksState>(
      'emits TasksError when recordTaskEntry fails',
      build: () {
        when(() => mockRecordTaskEntry(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Failed to record')));
        return tasksBloc;
      },
      act: (bloc) => bloc.add(RecordEntrySubmitted(
        taskId: 't1',
        entryDate: now,
        status: 'done',
      )),
      expect: () => [
        const TasksError('Failed to record'),
      ],
    );
  });
}

