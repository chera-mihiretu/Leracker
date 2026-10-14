import '../../domain/entities/daily_log.dart';
import 'task_model.dart';

/// Data model that extends the domain [DailyLog] entity with
/// JSON serialization / deserialization.
class DailyLogModel extends DailyLog {
  const DailyLogModel({
    required super.date,
    required super.tasks,
  });

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      date: DateTime.parse(json['date'] as String),
      tasks: (json['tasks'] as List<dynamic>)
          .map((t) => TaskModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'tasks': tasks.map((t) => TaskModel.fromEntity(t).toJson()).toList(),
    };
  }
}
