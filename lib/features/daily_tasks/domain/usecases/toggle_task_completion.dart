import '../../../../core/usecases/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

class ToggleTaskCompletion extends UseCase<Task, String> {
  final TaskRepository repository;

  ToggleTaskCompletion(this.repository);

  @override
  Future<Task> call(String taskId) {
    return repository.toggleTaskCompletion(taskId);
  }
}
