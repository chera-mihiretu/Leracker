import 'package:equatable/equatable.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_entry_entity.dart';

abstract class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => [];
}

class TasksInitial extends TasksState {
  const TasksInitial();
}

class TasksLoading extends TasksState {
  const TasksLoading();
}

class TasksLoaded extends TasksState {
  final List<TaskEntity> tasks;
  final Map<String, List<TaskEntryEntity>> entriesByTaskId;

  const TasksLoaded({
    required this.tasks,
    required this.entriesByTaskId,
  });

  @override
  List<Object?> get props => [tasks, entriesByTaskId];
}

class TasksError extends TasksState {
  final String message;

  const TasksError(this.message);

  @override
  List<Object?> get props => [message];
}

