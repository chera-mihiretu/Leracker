import 'package:flutter/material.dart';

import '../bloc/tasks_bloc.dart';
import '../bloc/tasks_event.dart';
import '../bloc/tasks_state.dart';
import '../widgets/contribution_grid.dart';
import '../widgets/streak_card.dart';
import '../widgets/completion_chart.dart';
import '../../domain/entities/daily_log.dart';

/// Main dashboard showing the contribution grid, streak, and chart.
class DashboardPage extends StatefulWidget {
  final TasksBloc bloc;

  const DashboardPage({super.key, required this.bloc});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    widget.bloc.add(LoadCompletionHistory(
      startDate: now.subtract(const Duration(days: 365)),
      endDate: now,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Tracker')),
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

          final logs = state is CompletionHistoryLoaded
              ? state.logs
              : <DailyLog>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak card
                const StreakCard(currentStreak: 0, longestStreak: 0),
                const SizedBox(height: 24),

                // Contribution grid
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ContributionGrid(logs: logs),
                const SizedBox(height: 24),

                // Completion chart
                Text(
                  'Completion Rate',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                CompletionChart(logs: logs),
              ],
            ),
          );
        },
      ),
    );
  }
}
