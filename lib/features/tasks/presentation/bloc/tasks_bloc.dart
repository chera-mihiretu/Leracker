import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_entry_entity.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/get_task_entries.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/record_task_entry.dart';
import '../../domain/usecases/sync_tasks.dart';
import 'tasks_event.dart';
import 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final GetTasks getTasks;
  final AddTask addTask;
  final GetTaskEntries getTaskEntries;
  final RecordTaskEntry recordTaskEntry;
  final SyncTasks? syncTasks;
  final Duration? syncInterval;
  Timer? _syncTimer;

  TasksBloc({
    required this.getTasks,
    required this.addTask,
    required this.getTaskEntries,
    required this.recordTaskEntry,
    this.syncTasks,
    this.syncInterval = const Duration(seconds: 15),
    bool autoStartSyncTimer = false,
  }) : super(const TasksInitial()) {
    on<LoadTasksRequested>(_onLoadTasksRequested);
    on<AddTaskSubmitted>(_onAddTaskSubmitted);
    on<RecordEntrySubmitted>(_onRecordEntrySubmitted);
    on<SyncTasksRequested>(_onSyncTasksRequested);

    if (autoStartSyncTimer && syncInterval != null && syncTasks != null) {
      startPeriodicSync(syncInterval!);
    }
  }

  void startPeriodicSync([Duration interval = const Duration(seconds: 15)]) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) {
      add(const SyncTasksRequested());
    });
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadTasksRequested(
    LoadTasksRequested event,
    Emitter<TasksState> emit,
  ) async {
    emit(const TasksLoading());
    final tasksResult = await getTasks(const NoParams());
    final entriesResult = await getTaskEntries(const NoParams());

    tasksResult.fold(
      (failure) => emit(TasksError(failure.message)),
      (tasks) {
        entriesResult.fold(
          (failure) => emit(TasksLoaded(tasks: tasks, entriesByTaskId: const {})),
          (entries) => emit(TasksLoaded(tasks: tasks, entriesByTaskId: entries)),
        );
      },
    );
  }

  Future<void> _onAddTaskSubmitted(
    AddTaskSubmitted event,
    Emitter<TasksState> emit,
  ) async {
    final result = await addTask(
      AddTaskParams(
        name: event.name,
        frequencyType: event.frequencyType,
        daysOfWeek: event.daysOfWeek,
        monthlyRule: event.monthlyRule,
        startTime: event.startTime,
        reminderCount: event.reminderCount,
        gridColor: event.gridColor,
        includeInMorningReview: event.includeInMorningReview,
      ),
    );

    result.fold(
      (failure) => emit(TasksError(failure.message)),
      (newTask) {
        if (state is TasksLoaded) {
          final current = state as TasksLoaded;
          emit(TasksLoaded(
            tasks: [...current.tasks, newTask],
            entriesByTaskId: current.entriesByTaskId,
          ));
        } else {
          emit(TasksLoaded(
            tasks: [newTask],
            entriesByTaskId: const {},
          ));
        }
      },
    );
  }

  Future<void> _onRecordEntrySubmitted(
    RecordEntrySubmitted event,
    Emitter<TasksState> emit,
  ) async {
    final result = await recordTaskEntry(
      RecordTaskEntryParams(
        taskId: event.taskId,
        entryDate: event.entryDate,
        status: event.status,
      ),
    );

    result.fold(
      (failure) => emit(TasksError(failure.message)),
      (newEntry) {
        if (state is TasksLoaded) {
          final current = state as TasksLoaded;
          final updatedEntries =
              Map<String, List<TaskEntryEntity>>.from(current.entriesByTaskId);
          final list = List<TaskEntryEntity>.from(
              updatedEntries[event.taskId] ?? <TaskEntryEntity>[]);

          final index = list.indexWhere(
            (e) =>
                e.entryDate.year == newEntry.entryDate.year &&
                e.entryDate.month == newEntry.entryDate.month &&
                e.entryDate.day == newEntry.entryDate.day,
          );
          if (index >= 0) {
            list[index] = newEntry;
          } else {
            list.add(newEntry);
          }
          updatedEntries[event.taskId] = list;

          emit(TasksLoaded(
            tasks: current.tasks,
            entriesByTaskId: updatedEntries,
          ));
        }
      },
    );
  }

  Future<void> _onSyncTasksRequested(
    SyncTasksRequested event,
    Emitter<TasksState> emit,
  ) async {
    if (syncTasks == null) return;
    final result = await syncTasks!(const NoParams());
    result.fold(
      (_) {},
      (uploadedTasks) {
        if (uploadedTasks.isNotEmpty && state is TasksLoaded) {
          final current = state as TasksLoaded;
          final updatedTasks = List<TaskEntity>.from(current.tasks);

          for (final uploaded in uploadedTasks) {
            final index = updatedTasks.indexWhere(
              (t) =>
                  t.id == uploaded.id ||
                  (!t.isUploaded && t.name == uploaded.name),
            );
            if (index >= 0) {
              updatedTasks[index] = uploaded;
            } else {
              updatedTasks.add(uploaded);
            }
          }

          emit(TasksLoaded(
            tasks: updatedTasks,
            entriesByTaskId: current.entriesByTaskId,
          ));
        }
      },
    );
  }
}
