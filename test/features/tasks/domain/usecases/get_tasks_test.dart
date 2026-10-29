import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/core/usecases/usecase.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entity.dart';
import 'package:progress_tracker/features/tasks/domain/repositories/task_repository.dart';
import 'package:progress_tracker/features/tasks/domain/usecases/get_tasks.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late GetTasks useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = GetTasks(mockRepository);
  });

  final testTasks = [
    TaskEntity(
      id: 't1',
      userId: 'u1',
      name: 'Task 1',
      createdAt: DateTime.now(),
    ),
  ];

  test('returns list of tasks on success', () async {
    when(() => mockRepository.getTasks())
        .thenAnswer((_) async => Right(testTasks));

    final result = await useCase(const NoParams());

    expect(result, Right(testTasks));
    verify(() => mockRepository.getTasks()).called(1);
  });

  test('returns failure when repository fails', () async {
    const failure = CacheFailure(message: 'Error');
    when(() => mockRepository.getTasks())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
    verify(() => mockRepository.getTasks()).called(1);
  });
}

