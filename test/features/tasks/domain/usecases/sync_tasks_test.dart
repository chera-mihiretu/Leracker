import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/core/usecases/usecase.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entity.dart';
import 'package:progress_tracker/features/tasks/domain/repositories/task_repository.dart';
import 'package:progress_tracker/features/tasks/domain/usecases/sync_tasks.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late SyncTasks useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = SyncTasks(mockRepository);
  });

  final testTask = TaskEntity(
    id: 't1',
    userId: 'u1',
    name: 'Workout',
    createdAt: DateTime.now(),
    isUploaded: true,
  );

  test(
    'calls syncUnsyncedTasks and returns uploaded tasks on success',
    () async {
      when(
        () => mockRepository.syncUnsyncedTasks(),
      ).thenAnswer((_) async => Right([testTask]));

      final result = await useCase(const NoParams());

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), equals([testTask]));
      verify(() => mockRepository.syncUnsyncedTasks()).called(1);
    },
  );

  test('returns failure when repository fails', () async {
    const failure = ServerFailure(message: 'Sync failed');
    when(
      () => mockRepository.syncUnsyncedTasks(),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
    verify(() => mockRepository.syncUnsyncedTasks()).called(1);
  });
}
