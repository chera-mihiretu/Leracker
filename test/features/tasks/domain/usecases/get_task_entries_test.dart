import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/core/usecases/usecase.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entry_entity.dart';
import 'package:progress_tracker/features/tasks/domain/repositories/task_repository.dart';
import 'package:progress_tracker/features/tasks/domain/usecases/get_task_entries.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late GetTaskEntries useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = GetTaskEntries(mockRepository);
  });

  final testMap = <String, List<TaskEntryEntity>>{
    't1': [
      TaskEntryEntity(
        id: 'e1',
        taskId: 't1',
        userId: 'u1',
        entryDate: DateTime(2026, 1, 1),
        status: 'done',
        answeredAt: DateTime(2026, 1, 1),
      ),
    ],
  };

  test('returns map of entries on success', () async {
    when(() => mockRepository.getAllTaskEntries())
        .thenAnswer((_) async => Right(testMap));

    final result = await useCase(const NoParams());

    expect(result, Right(testMap));
  });

  test('returns failure on repository error', () async {
    const failure = CacheFailure(message: 'Error');
    when(() => mockRepository.getAllTaskEntries())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
  });
}

