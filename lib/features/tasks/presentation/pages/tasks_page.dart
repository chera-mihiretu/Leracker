import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/sign_in_page.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_entry_entity.dart';
import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';
import '../bloc/tasks_state.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/dashboard_store.dart';
import '../dashboard/task_item.dart';
import '../task_setup/task_draft.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final DashboardStore _store;

  @override
  void initState() {
    super.initState();
    _store = DashboardStore(
      onStatusChanged: (task, day, status) {
        if (status != null) {
          context.read<TasksBloc>().add(
                RecordEntrySubmitted(
                  taskId: task.id,
                  entryDate: day,
                  status: status == EntryStatus.done ? 'done' : 'missed',
                ),
              );
        }
      },
    );

    // Initial tasks load
    context.read<TasksBloc>().add(const LoadTasksRequested());
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  List<TaskItem> _mapTasks(
    List<TaskEntity> tasks,
    Map<String, List<TaskEntryEntity>> entriesByTaskId,
  ) {
    return tasks.map((task) {
      final entries = entriesByTaskId[task.id] ?? const [];
      final rule = task.monthlyRule;
      final start = task.startTime;
      final hex = task.gridColor.replaceFirst('#', '');
      final color = Color(int.parse('FF$hex', radix: 16));

      final freq = switch (task.frequencyType) {
        'weekly' => Frequency.weekly,
        'monthly' => Frequency.monthly,
        _ => Frequency.daily,
      };

      final monthDay = rule == null || rule == 'start'
          ? 1
          : rule == 'end'
              ? kEndOfMonth
              : (int.tryParse(rule) ?? 1);

      final startMinutes = start != null && start.length >= 5
          ? int.parse(start.substring(0, 2)) * 60 +
              int.parse(start.substring(3, 5))
          : null;

      return TaskItem(
        id: task.id,
        name: task.name,
        frequency: freq,
        daysOfWeek: task.daysOfWeek.map((d) => d - 1).toSet(),
        monthDay: monthDay,
        startMinutes: startMinutes,
        reminderCount: task.reminderCount,
        gridColor: color,
        includeInMorningReview: task.includeInMorningReview,
        createdAt: task.createdAt,
        entries: {
          for (final e in entries)
            dateOnly(e.entryDate):
                e.isDone ? EntryStatus.done : EntryStatus.missed,
        },
      );
    }).toList();
  }

  void _handleDraftCreated(TaskDraft draft) {
    final frequencyType = switch (draft.frequency) {
      Frequency.daily => 'daily',
      Frequency.weekly => 'weekly',
      Frequency.monthly => 'monthly',
    };

    final daysOfWeek = switch (draft.frequency) {
      Frequency.daily => draft.days.map((d) => d + 1).toList()..sort(),
      Frequency.weekly => [draft.weekDay + 1],
      Frequency.monthly => const [1, 2, 3, 4, 5, 6, 7],
    };

    final monthlyRule = switch (draft.frequency) {
      Frequency.monthly => draft.monthDay == kEndOfMonth
          ? 'end'
          : draft.monthDay == 1
              ? 'start'
              : draft.monthDay.toString(),
      _ => null,
    };

    final startTime = '${draft.timeLabel}:00';
    final gridColor =
        // ignore: deprecated_member_use
        '#${(draft.color.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    context.read<TasksBloc>().add(
          AddTaskSubmitted(
            name: draft.name.trim(),
            frequencyType: frequencyType,
            daysOfWeek: daysOfWeek,
            monthlyRule: monthlyRule,
            startTime: startTime,
            reminderCount: draft.nudges,
            gridColor: gridColor,
            includeInMorningReview: draft.morningReview,
          ),
        );
  }

  void _handleSignOut() {
    context.read<AuthBloc>().add(const SignOutRequested());
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignInPage()),
    );
  }

  String _getUserInitials(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      final name = authState.user.displayName?.trim();
      if (name != null && name.isNotEmpty) {
        final parts = name.split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
        return parts.map((s) => s[0].toUpperCase()).take(2).join();
      }
      final email = authState.user.email?.trim();
      if (email != null && email.isNotEmpty) {
        return email.substring(0, 1).toUpperCase();
      }
    }
    return 'PT';
  }

  String? _getUserAvatarUrl(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.avatarUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getUserInitials(context);
    final avatarUrl = _getUserAvatarUrl(context);

    return BlocConsumer<TasksBloc, TasksState>(
      listener: (context, state) {
        if (state is TasksLoaded) {
          _store.syncFromTasks(_mapTasks(state.tasks, state.entriesByTaskId));
        }
      },
      builder: (context, state) {
        if (state is TasksLoading && _store.tasks.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is TasksError && _store.tasks.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context
                        .read<TasksBloc>()
                        .add(const LoadTasksRequested()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // If tasks have loaded, ensure store is updated
        if (state is TasksLoaded && _store.tasks.isEmpty && state.tasks.isNotEmpty) {
          _store.syncFromTasks(_mapTasks(state.tasks, state.entriesByTaskId));
        }

        return DashboardScreen(
          store: _store,
          userInitials: initials,
          userAvatarUrl: avatarUrl,
          onSignOut: _handleSignOut,
          onDraftCreated: _handleDraftCreated,
        );
      },
    );
  }
}
