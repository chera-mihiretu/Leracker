import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entry_entity.dart';
import 'package:progress_tracker/features/tasks/domain/repositories/task_repository.dart';
import 'package:progress_tracker/features/tasks/domain/usecases/record_task_entry.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late RecordTaskEntry useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = RecordTaskEntry(mockRepository);
  });

  final testDate = DateTime(2026, 1, 1);
  final testEntry = TaskEntryEntity(
    id: 'e1',
    taskId: 't1',
    userId: 'u1',
    entryDate: testDate,
    status: 'done',
    answeredAt: testDate,
  );

  test('returns recorded entry on success', () async {
    when(() => mockRepository.recordTaskEntry(
          taskId: 't1',
          entryDate: testDate,
          status: 'done',
        )).thenAnswer((_) async => Right(testEntry));

    final result = await useCase(RecordTaskEntryParams(
      taskId: 't1',
      entryDate: testDate,
      status: 'done',
    ));

    expect(result, Right(testEntry));
    verify(() => mockRepository.recordTaskEntry(
          taskId: 't1',
          entryDate: testDate,
          status: 'done',
        )).called(1);
  });

  test('returns failure on error', () async {
    const failure = ServerFailure(message: 'Error recording entry');
    when(() => mockRepository.recordTaskEntry(
          taskId: 't1',
          entryDate: testDate,
          status: 'done',
        )).thenAnswer((_) async => const Left(failure));

    final result = await useCase(RecordTaskEntryParams(
      taskId: 't1',
      entryDate: testDate,
      status: 'done',
    ));

    expect(result, const Left(failure));
  });
}

