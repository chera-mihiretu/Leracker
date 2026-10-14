import 'package:flutter/material.dart';

import '../../domain/entities/daily_log.dart';

/// A simple bar chart showing completion rates over time.
class CompletionChart extends StatelessWidget {
  final List<DailyLog> logs;

  const CompletionChart({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (logs.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No data yet')),
      );
    }

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: logs.map((log) {
          final rate = log.completionRate;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Tooltip(
                message:
                    '${log.date.month}/${log.date.day}: ${(rate * 100).round()}%',
                child: FractionallySizedBox(
                  heightFactor: rate == 0 ? 0.05 : rate,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
