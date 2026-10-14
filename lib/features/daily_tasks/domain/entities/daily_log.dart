import 'package:flutter/foundation.dart';

import 'task.dart';

/// A snapshot of one day's task completions.
@immutable
class DailyLog {
  final DateTime date;
  final List<Task> tasks;

  const DailyLog({
    required this.date,
    required this.tasks,
  });

  /// Number of completed tasks on this day.
  int get completedCount => tasks.where((t) => t.isCompleted).length;

  /// Total tasks scheduled for this day.
  int get totalCount => tasks.length;

  /// Completion ratio (0.0 – 1.0).
  double get completionRate =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;

  DailyLog copyWith({
    DateTime? date,
    List<Task>? tasks,
  }) {
    return DailyLog(
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLog && date == other.date;

  @override
  int get hashCode => date.hashCode;
}
