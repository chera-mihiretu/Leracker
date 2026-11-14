import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class SyncTasks implements UseCase<Either<Failure, List<TaskEntity>>, NoParams> {
  final TaskRepository repository;

  SyncTasks(this.repository);

  @override
  Future<Either<Failure, List<TaskEntity>>> call(NoParams params) {
    return repository.syncUnsyncedTasks();
  }
}

