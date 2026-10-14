import 'package:flutter/material.dart';

import '../../domain/entities/daily_log.dart';

/// A GitHub / LeetCode-style contribution grid showing daily completion.
class ContributionGrid extends StatelessWidget {
  final List<DailyLog> logs;
  final int columns;

  const ContributionGrid({
    super.key,
    required this.logs,
    this.columns = 52,
  });

  Color _cellColor(double completionRate, ColorScheme colorScheme) {
    if (completionRate == 0) return colorScheme.surfaceContainerHighest;
    if (completionRate < 0.25) return colorScheme.primary.withValues(alpha: 0.25);
    if (completionRate < 0.50) return colorScheme.primary.withValues(alpha: 0.50);
    if (completionRate < 0.75) return colorScheme.primary.withValues(alpha: 0.75);
    return colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Tooltip(
          message:
              '${log.date.month}/${log.date.day}: ${log.completedCount}/${log.totalCount}',
          child: Container(
            decoration: BoxDecoration(
              color: _cellColor(log.completionRate, colorScheme),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
    );
  }
}
