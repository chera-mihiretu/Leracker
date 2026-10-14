import '../../../../core/usecases/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class AddTask extends UseCase<Task, Task> {
  final TaskRepository repository;

  AddTask(this.repository);

  @override
  Future<Task> call(Task task) {
    return repository.addTask(task);
  }
}
