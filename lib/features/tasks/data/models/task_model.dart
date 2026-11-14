import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.userId,
    required super.name,
    super.frequencyType = 'daily',
    super.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7],
    super.monthlyRule,
    super.startTime,
    super.reminderCount = 1,
    super.gridColor = '#22C55E',
    super.includeInMorningReview = true,
    required super.createdAt,
    super.archived = false,
    super.isUploaded = true,
    super.frequency,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days_of_week'];
    List<int> parsedDays = const [1, 2, 3, 4, 5, 6, 7];
    if (rawDays is List) {
      parsedDays = rawDays.map((e) => (e as num).toInt()).toList();
    }

    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? 'local_user',
      name: json['name'] as String,
      frequencyType: json['frequency_type'] as String? ??
          json['frequency'] as String? ??
          'daily',
      daysOfWeek: parsedDays,
      monthlyRule: json['monthly_rule'] as String?,
      startTime: json['start_time'] as String?,
      reminderCount: (json['reminder_count'] as num?)?.toInt() ?? 1,
      gridColor: json['grid_color'] as String? ?? '#22C55E',
      includeInMorningReview:
          json['include_in_morning_review'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      archived: json['archived'] as bool? ?? false,
      isUploaded: json['is_uploaded'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'frequency_type': frequencyType,
      'frequency': frequencyType,
      'days_of_week': daysOfWeek,
      'monthly_rule': monthlyRule,
      'start_time': startTime,
      'reminder_count': reminderCount,
      'grid_color': gridColor,
      'include_in_morning_review': includeInMorningReview,
      'created_at': createdAt.toIso8601String(),
      'archived': archived,
      'is_uploaded': isUploaded,
    };
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      frequencyType: entity.frequencyType,
      daysOfWeek: entity.daysOfWeek,
      monthlyRule: entity.monthlyRule,
      startTime: entity.startTime,
      reminderCount: entity.reminderCount,
      gridColor: entity.gridColor,
      includeInMorningReview: entity.includeInMorningReview,
      createdAt: entity.createdAt,
      archived: entity.archived,
      isUploaded: entity.isUploaded,
    );
  }

  @override
  TaskModel copyWith({
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
    return TaskModel(
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
}

