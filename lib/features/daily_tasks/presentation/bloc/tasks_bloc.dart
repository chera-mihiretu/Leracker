import 'dart:async';

import '../../domain/entities/task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/toggle_task_completion.dart';
import '../../domain/usecases/get_completion_history.dart';
import 'tasks_event.dart';
import 'tasks_state.dart';

/// A minimal BLoC (Business Logic Component) for task management.
///
/// Uses a simple Stream-based approach. Swap in flutter_bloc or
/// bloc packages for a more robust implementation later.
class TasksBloc {
  final GetTasks _getTasks;
  final AddTask _addTask;
  final ToggleTaskCompletion _toggleTaskCompletion;
  final GetCompletionHistory _getCompletionHistory;

  final _stateController = StreamController<TasksState>.broadcast();
  final _eventController = StreamController<TasksEvent>();

  Stream<TasksState> get state => _stateController.stream;
  TasksState _currentState = const TasksInitial();
  TasksState get currentState => _currentState;

  DateTime _selectedDate = DateTime.now();

  TasksBloc({
    required GetTasks getTasks,
    required AddTask addTask,
    required ToggleTaskCompletion toggleTaskCompletion,
    required GetCompletionHistory getCompletionHistory,
  })  : _getTasks = getTasks,
        _addTask = addTask,
        _toggleTaskCompletion = toggleTaskCompletion,
        _getCompletionHistory = getCompletionHistory {
    _eventController.stream.listen(_mapEventToState);
  }

  void add(TasksEvent event) {
    _eventController.add(event);
  }

  void _emit(TasksState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> _mapEventToState(TasksEvent event) async {
    switch (event) {
      case LoadTasks():
        await _onLoadTasks(event);
      case AddNewTask():
        await _onAddTask(event);
      case ToggleTask():
        await _onToggleTask(event);
      case DeleteTaskEvent():
        // TODO: implement delete
        break;
      case LoadCompletionHistory():
        await _onLoadHistory(event);
    }
  }

  Future<void> _onLoadTasks(LoadTasks event) async {
    _emit(const TasksLoading());
    try {
      _selectedDate = event.date;
      final tasks = await _getTasks(event.date);
      _emit(TasksLoaded(tasks: tasks, date: event.date));
    } catch (e) {
      _emit(TasksError(e.toString()));
    }
  }

  Future<void> _onAddTask(AddNewTask event) async {
    try {
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: event.title,
        description: event.description,
        createdAt: DateTime.now(),
      );
      await _addTask(task);
      add(LoadTasks(_selectedDate));
    } catch (e) {
      _emit(TasksError(e.toString()));
    }
  }

  Future<void> _onToggleTask(ToggleTask event) async {
    try {
      await _toggleTaskCompletion(event.taskId);
      add(LoadTasks(_selectedDate));
    } catch (e) {
      _emit(TasksError(e.toString()));
    }
  }

  Future<void> _onLoadHistory(LoadCompletionHistory event) async {
    try {
      final params = HistoryParams(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      final logs = await _getCompletionHistory(params);
      _emit(CompletionHistoryLoaded(logs));
    } catch (e) {
      _emit(TasksError(e.toString()));
    }
  }

  void dispose() {
    _stateController.close();
    _eventController.close();
  }
}
