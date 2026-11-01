import 'package:flutter/material.dart';
import '../../domain/entities/task_entry_entity.dart';

class GreenGrid extends StatelessWidget {
  final List<TaskEntryEntity> entries;
  final int daysToShow;
  final void Function(DateTime date)? onDayTap;

  const GreenGrid({
    super.key,
    required this.entries,
    this.daysToShow = 35, // 5 weeks of 7 days
    this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Create list of dates from (today - daysToShow + 1) to today
    final dates = List.generate(daysToShow, (i) {
      return today.subtract(Duration(days: daysToShow - 1 - i));
    });

    final entryMap = <String, TaskEntryEntity>{};
    for (final e in entries) {
      final key =
          '${e.entryDate.year}-${e.entryDate.month.toString().padLeft(2, '0')}-${e.entryDate.day.toString().padLeft(2, '0')}';
      entryMap[key] = e;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: dates.map((date) {
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final entry = entryMap[key];

          Color cellColor;
          Border? cellBorder;

          if (entry != null && entry.isDone) {
            cellColor = Colors.green.shade600;
          } else if (entry != null && entry.isMissed) {
            cellColor = Colors.grey.shade400;
          } else {
            cellColor = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
            cellBorder = Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              width: 0.5,
            );
          }

          final isCurrentDay = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;

          return GestureDetector(
            onTap: onDayTap != null ? () => onDayTap!(date) : null,
            child: Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 1.5, vertical: 2),
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(3),
                border: cellBorder ??
                    (isCurrentDay
                        ? Border.all(color: Colors.green.shade800, width: 1.2)
                        : null),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

