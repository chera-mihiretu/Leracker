import 'package:flutter/foundation.dart';

import '../../domain/entities/task.dart';
import '../../domain/entities/daily_log.dart';

@immutable
abstract class TasksState {
  const TasksState();
}

class TasksInitial extends TasksState {
  const TasksInitial();
}

class TasksLoading extends TasksState {
  const TasksLoading();
}

class TasksLoaded extends TasksState {
  final List<Task> tasks;
  final DateTime date;

  const TasksLoaded({required this.tasks, required this.date});
}

class TasksError extends TasksState {
  final String message;
  const TasksError(this.message);
}

class CompletionHistoryLoaded extends TasksState {
  final List<DailyLog> logs;
  const CompletionHistoryLoaded(this.logs);
}
