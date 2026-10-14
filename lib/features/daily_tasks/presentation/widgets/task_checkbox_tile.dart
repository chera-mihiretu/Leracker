import 'package:flutter/material.dart';

import '../../domain/entities/task.dart';

/// A single task row with a checkbox.
class TaskCheckboxTile extends StatelessWidget {
  final Task task;
  final ValueChanged<String> onToggle;

  const TaskCheckboxTile({
    super.key,
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (_) => onToggle(task.id),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted
              ? Theme.of(context).colorScheme.outline
              : null,
        ),
      ),
      subtitle: task.description != null ? Text(task.description!) : null,
    );
  }
}
