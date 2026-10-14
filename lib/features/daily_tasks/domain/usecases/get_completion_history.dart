import 'package:flutter/foundation.dart';

import '../../../../core/usecases/usecase.dart';
import '../entities/daily_log.dart';
import '../repositories/task_repository.dart';

@immutable
class HistoryParams {
  final DateTime startDate;
  final DateTime endDate;

  const HistoryParams({required this.startDate, required this.endDate});
}

class GetCompletionHistory extends UseCase<List<DailyLog>, HistoryParams> {
  final TaskRepository repository;

  GetCompletionHistory(this.repository);

  @override
  Future<List<DailyLog>> call(HistoryParams params) {
    return repository.getCompletionHistory(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
