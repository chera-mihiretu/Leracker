import '../../domain/entities/task_entry_entity.dart';

class TaskEntryModel extends TaskEntryEntity {
  const TaskEntryModel({
    required super.id,
    required super.taskId,
    required super.userId,
    required super.entryDate,
    required super.status,
    required super.answeredAt,
  });

  factory TaskEntryModel.fromJson(Map<String, dynamic> json) {
    return TaskEntryModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      userId: json['user_id'] as String,
      entryDate: DateTime.parse(json['entry_date'] as String),
      status: json['status'] as String,
      answeredAt: DateTime.parse(json['answered_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'entry_date':
          '${entryDate.year.toString().padLeft(4, '0')}-${entryDate.month.toString().padLeft(2, '0')}-${entryDate.day.toString().padLeft(2, '0')}',
      'status': status,
      'answered_at': answeredAt.toIso8601String(),
    };
  }

  factory TaskEntryModel.fromEntity(TaskEntryEntity entity) {
    return TaskEntryModel(
      id: entity.id,
      taskId: entity.taskId,
      userId: entity.userId,
      entryDate: entity.entryDate,
      status: entity.status,
      answeredAt: entity.answeredAt,
    );
  }
}

