import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String frequencyType; // 'daily', 'weekly', 'monthly'
  final List<int> daysOfWeek; // 1 = Mon ... 7 = Sun
  final String? monthlyRule; // 'start', 'end', or day '1'..'31'
  final String? startTime; // e.g. '08:00'
  final int reminderCount; // 0, 1, 2, 3
  final String gridColor; // e.g. '#22C55E'
  final bool includeInMorningReview;
  final DateTime createdAt;
  final bool archived;
  final bool isUploaded;

  const TaskEntity({
    required this.id,
    required this.userId,
    required this.name,
    String frequencyType = 'daily',
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    this.monthlyRule,
    this.startTime,
    this.reminderCount = 1,
    this.gridColor = '#22C55E',
    this.includeInMorningReview = true,
    required this.createdAt,
    this.archived = false,
    this.isUploaded = true,
    String? frequency,
  }) : frequencyType = frequency ?? frequencyType;

  /// Alias for backward compatibility
  String get frequency => frequencyType;

  TaskEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? frequencyType,
    String? frequency,
    List<int>? daysOfWeek,
    String? monthlyRule,
    String? startTime,
    int? reminderCount,
    String? gridColor,
    bool? includeInMorningReview,
    DateTime? createdAt,
    bool? archived,
    bool? isUploaded,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      frequencyType: frequencyType ?? frequency ?? this.frequencyType,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      monthlyRule: monthlyRule ?? this.monthlyRule,
      startTime: startTime ?? this.startTime,
      reminderCount: reminderCount ?? this.reminderCount,
      gridColor: gridColor ?? this.gridColor,
      includeInMorningReview:
          includeInMorningReview ?? this.includeInMorningReview,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        frequencyType,
        daysOfWeek,
        monthlyRule,
        startTime,
        reminderCount,
        gridColor,
        includeInMorningReview,
        createdAt,
        archived,
        isUploaded,
      ];
}

