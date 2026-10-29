import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entity.dart';
import 'package:progress_tracker/features/tasks/domain/repositories/task_repository.dart';
import 'package:progress_tracker/features/tasks/domain/usecases/add_task.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late AddTask useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = AddTask(mockRepository);
  });

  final testTask = TaskEntity(
    id: 't1',
    userId: 'u1',
    name: 'Workout',
    createdAt: DateTime.now(),
  );

  test('returns created task on success', () async {
    when(() => mockRepository.addTask(
          name: any(named: 'name'),
          frequencyType: any(named: 'frequencyType'),
          daysOfWeek: any(named: 'daysOfWeek'),
          monthlyRule: any(named: 'monthlyRule'),
          startTime: any(named: 'startTime'),
          reminderCount: any(named: 'reminderCount'),
          gridColor: any(named: 'gridColor'),
          includeInMorningReview: any(named: 'includeInMorningReview'),
        )).thenAnswer((_) async => Right(testTask));

    final result = await useCase(const AddTaskParams(name: 'Workout'));

    expect(result, Right(testTask));
    verify(() => mockRepository.addTask(
          name: 'Workout',
          frequencyType: 'daily',
          daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
          monthlyRule: null,
          startTime: null,
          reminderCount: 1,
          gridColor: '#22C55E',
          includeInMorningReview: true,
        )).called(1);
  });

  test('returns failure on error', () async {
    const failure = ServerFailure(message: 'Could not create task');
    when(() => mockRepository.addTask(
          name: any(named: 'name'),
          frequencyType: any(named: 'frequencyType'),
          daysOfWeek: any(named: 'daysOfWeek'),
          monthlyRule: any(named: 'monthlyRule'),
          startTime: any(named: 'startTime'),
          reminderCount: any(named: 'reminderCount'),
          gridColor: any(named: 'gridColor'),
          includeInMorningReview: any(named: 'includeInMorningReview'),
        )).thenAnswer((_) async => const Left(failure));

    final result = await useCase(const AddTaskParams(name: 'Workout'));

    expect(result, const Left(failure));
  });
}

