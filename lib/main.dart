import 'package:flutter/material.dart';

import 'features/daily_tasks/presentation/pages/dashboard_page.dart';
import 'features/daily_tasks/presentation/pages/task_list_page.dart';
import 'features/daily_tasks/presentation/bloc/tasks_bloc.dart';
import 'features/daily_tasks/domain/usecases/get_tasks.dart';
import 'features/daily_tasks/domain/usecases/add_task.dart';
import 'features/daily_tasks/domain/usecases/toggle_task_completion.dart';
import 'features/daily_tasks/domain/usecases/get_completion_history.dart';
import 'features/daily_tasks/data/repositories/task_repository_impl.dart';
import 'features/daily_tasks/data/data_sources/task_local_data_source.dart';
import 'features/daily_tasks/data/models/task_model.dart';

void main() {
  // ── Dependency Injection (manual; swap with get_it later) ──
  final localDataSource = _InMemoryTaskDataSource();
  final repository = TaskRepositoryImpl(localDataSource: localDataSource);

  final tasksBloc = TasksBloc(
    getTasks: GetTasks(repository),
    addTask: AddTask(repository),
    toggleTaskCompletion: ToggleTaskCompletion(repository),
    getCompletionHistory: GetCompletionHistory(repository),
  );

  runApp(ProgressTrackerApp(bloc: tasksBloc));
}

class ProgressTrackerApp extends StatelessWidget {
  final TasksBloc bloc;

  const ProgressTrackerApp({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progress Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _MainShell(bloc: bloc),
    );
  }
}

/// Bottom navigation shell with Dashboard and Task List tabs.
class _MainShell extends StatefulWidget {
  final TasksBloc bloc;
  const _MainShell({required this.bloc});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(bloc: widget.bloc),
      TaskListPage(bloc: widget.bloc),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }
}

// ── Temporary in-memory data source for development ──

class _InMemoryTaskDataSource implements TaskLocalDataSource {
  final List<TaskModel> _tasks = [];

  @override
  Future<List<TaskModel>> getTasks(DateTime date) async {
    return _tasks.where((t) {
      return t.createdAt.year == date.year &&
          t.createdAt.month == date.month &&
          t.createdAt.day == date.day;
    }).toList();
  }

  @override
  Future<TaskModel> saveTask(TaskModel task) async {
    _tasks.add(task);
    return task;
  }

  @override
  Future<TaskModel> toggleTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) throw Exception('Task not found');
    final old = _tasks[index];
    final updated = TaskModel(
      id: old.id,
      title: old.title,
      description: old.description,
      isCompleted: !old.isCompleted,
      createdAt: old.createdAt,
      completedAt: !old.isCompleted ? DateTime.now() : null,
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
  }

  @override
  Future<List<Map<String, dynamic>>> getCompletionHistory({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Return empty for now — implement with real DB later
    return [];
  }
}
