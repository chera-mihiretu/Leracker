import 'package:flutter/foundation.dart';

import '../../domain/entities/task.dart';

@immutable
abstract class TasksEvent {
  const TasksEvent();
}

/// Load tasks for a given date.
class LoadTasks extends TasksEvent {
  final DateTime date;
  const LoadTasks(this.date);
}

/// Add a new task.
class AddNewTask extends TasksEvent {
  final String title;
  final String? description;
  const AddNewTask({required this.title, this.description});
}

/// Toggle a task's completion status.
class ToggleTask extends TasksEvent {
  final String taskId;
  const ToggleTask(this.taskId);
}

/// Delete a task.
class DeleteTaskEvent extends TasksEvent {
  final String taskId;
  const DeleteTaskEvent(this.taskId);
}

/// Load completion history for the contribution grid.
class LoadCompletionHistory extends TasksEvent {
  final DateTime startDate;
  final DateTime endDate;
  const LoadCompletionHistory({required this.startDate, required this.endDate});
}
