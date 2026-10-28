import 'package:equatable/equatable.dart';

class TaskEntryEntity extends Equatable {
  final String id;
  final String taskId;
  final String userId;
  final DateTime entryDate;
  final String status; // 'done' or 'missed'
  final DateTime answeredAt;

  const TaskEntryEntity({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.entryDate,
    required this.status,
    required this.answeredAt,
  });

  bool get isDone => status == 'done';
  bool get isMissed => status == 'missed';

  @override
  List<Object?> get props => [id, taskId, userId, entryDate, status, answeredAt];
}

