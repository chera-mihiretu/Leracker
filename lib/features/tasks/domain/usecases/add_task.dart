import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class AddTaskParams extends Equatable {
  final String name;
  final String frequencyType;
  final List<int> daysOfWeek;
  final String? monthlyRule;
  final String? startTime;
  final int reminderCount;
  final String gridColor;
  final bool includeInMorningReview;

  const AddTaskParams({
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

class AddTask implements UseCase<Either<Failure, TaskEntity>, AddTaskParams> {
  final TaskRepository repository;

  AddTask(this.repository);

  @override
  Future<Either<Failure, TaskEntity>> call(AddTaskParams params) {
    return repository.addTask(
      name: params.name,
      frequencyType: params.frequencyType,
      daysOfWeek: params.daysOfWeek,
      monthlyRule: params.monthlyRule,
      startTime: params.startTime,
      reminderCount: params.reminderCount,
      gridColor: params.gridColor,
      includeInMorningReview: params.includeInMorningReview,
    );
  }
}

