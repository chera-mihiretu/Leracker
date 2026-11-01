import 'package:equatable/equatable.dart';

abstract class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasksRequested extends TasksEvent {
  const LoadTasksRequested();
}

class AddTaskSubmitted extends TasksEvent {
  final String name;
  final String frequencyType;
  final List<int> daysOfWeek;
  final String? monthlyRule;
  final String? startTime;
  final int reminderCount;
  final String gridColor;
  final bool includeInMorningReview;

  const AddTaskSubmitted({
    required this.name,
    this.frequencyType = 'daily',
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.monthlyRule,
    this.startTime,
    this.reminderCount = 1,
    this.gridColor = '#22C55E',
    this.includeInMorningReview = true,
    String? frequency,
  });

  String get frequency => frequencyType;

  @override
  List<Object?> get props => [
        name,
        frequencyType,
        daysOfWeek,
        monthlyRule,
        startTime,
        reminderCount,
        gridColor,
        includeInMorningReview,
      ];
}

class RecordEntrySubmitted extends TasksEvent {
  final String taskId;
  final DateTime entryDate;
  final String status; // 'done' or 'missed'

  const RecordEntrySubmitted({
    required this.taskId,
    required this.entryDate,
    required this.status,
  });

  @override
  List<Object?> get props => [taskId, entryDate, status];
}

