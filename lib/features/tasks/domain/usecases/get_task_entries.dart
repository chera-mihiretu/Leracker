import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/task_entry_entity.dart';
import '../repositories/task_repository.dart';

class GetTaskEntries implements UseCase<Either<Failure, Map<String, List<TaskEntryEntity>>>, NoParams> {
  final TaskRepository repository;

  GetTaskEntries(this.repository);

  @override
  Future<Either<Failure, Map<String, List<TaskEntryEntity>>>> call(NoParams params) {
    return repository.getAllTaskEntries();
  }
}

