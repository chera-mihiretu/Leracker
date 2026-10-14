import '../../../../core/usecases/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTasks extends UseCase<List<Task>, DateTime> {
  final TaskRepository repository;

  GetTasks(this.repository);

  @override
  Future<List<Task>> call(DateTime date) {
    return repository.getTasks(date);
  }
}
