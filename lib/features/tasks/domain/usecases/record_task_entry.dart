import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/task_entry_entity.dart';
import '../repositories/task_repository.dart';

class RecordTaskEntryParams extends Equatable {
  final String taskId;
  final DateTime entryDate;
  final String status; // 'done' or 'missed'

  const RecordTaskEntryParams({
    required this.taskId,
    required this.entryDate,
    required this.status,
  });

  @override
  List<Object?> get props => [taskId, entryDate, status];
}

class RecordTaskEntry
    implements UseCase<Either<Failure, TaskEntryEntity>, RecordTaskEntryParams> {
  final TaskRepository repository;

  RecordTaskEntry(this.repository);

  @override
  Future<Either<Failure, TaskEntryEntity>> call(RecordTaskEntryParams params) {
    return repository.recordTaskEntry(
      taskId: params.taskId,
      entryDate: params.entryDate,
      status: params.status,
    );
  }
}

