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

  static const cell = 13.0;
  static const gap = 3.0;
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final weeks = (daysToShow / 7).ceil();
    final start =
        today.subtract(Duration(days: (today.weekday - 1) + 7 * (weeks - 1)));

    final entryMap = <String, TaskEntryEntity>{};
    for (final e in entries) {
      final key =
          '${e.entryDate.year}-${e.entryDate.month.toString().padLeft(2, '0')}-${e.entryDate.day.toString().padLeft(2, '0')}';
      entryMap[key] = e;
    }

    const h = 7 * (cell + gap) - gap;

    return SizedBox(
      height: h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day labels column
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var r = 0; r < 7; r++) ...[
                SizedBox(
                  height: cell,
                  width: 14,
                  child: Center(
                    child: Text(
                      _labels[r],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.7),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                if (r < 6) const SizedBox(height: gap),
              ],
            ],
          ),
          const SizedBox(width: 8),
          // 7xN matrix
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(weeks, (col) {
                  return Padding(
                    padding: EdgeInsets.only(right: col < weeks - 1 ? gap : 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(7, (row) {
                        final date = start.add(Duration(days: col * 7 + row));
                        final isFuture = date.isAfter(today);
                        if (isFuture) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: row < 6 ? gap : 0),
                            child: const SizedBox(width: cell, height: cell),
                          );
                        }

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
                          cellColor = Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4);
                          cellBorder = Border.all(
                            color: Theme.of(context)
                                .dividerColor
                                .withValues(alpha: 0.2),
                            width: 0.5,
                          );
                        }

                        final isCurrentDay = date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;

                        return Padding(
                          padding: EdgeInsets.only(bottom: row < 6 ? gap : 0),
                          child: GestureDetector(
                            onTap:
                                onDayTap != null ? () => onDayTap!(date) : null,
                            child: Container(
                              width: cell,
                              height: cell,
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(3),
                                border: cellBorder ??
                                    (isCurrentDay
                                        ? Border.all(
                                            color: Colors.green.shade800,
                                            width: 1.2)
                                        : null),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
