import 'package:flutter/material.dart';

import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';
import '../bloc/tasks_state.dart';
import '../widgets/task_checkbox_tile.dart';
import '../../domain/entities/task.dart';

/// Page displaying the list of tasks for the selected date.
class TaskListPage extends StatefulWidget {
  final TasksBloc bloc;

  const TaskListPage({super.key, required this.bloc});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  @override
  void initState() {
    super.initState();
    widget.bloc.add(LoadTasks(DateTime.now()));
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Task title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                widget.bloc.add(AddNewTask(title: title));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today\'s Tasks')),
      body: StreamBuilder<TasksState>(
        stream: widget.bloc.state,
        builder: (context, snapshot) {
          final state = snapshot.data;

          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TasksError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          final tasks =
              state is TasksLoaded ? state.tasks : <Task>[];

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks yet. Tap + to add one!'),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return TaskCheckboxTile(
                task: tasks[index],
                onToggle: (id) => widget.bloc.add(ToggleTask(id)),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
