import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/task_entry_entity.dart';

class GreenGrid extends StatefulWidget {
  final List<TaskEntryEntity> entries;
  final int? daysToShow;
  final DateTime? startDate;
  final DateTime? currentDate;
  final int? initialYear;
  final void Function(DateTime date)? onDayTap;

  const GreenGrid({
    super.key,
    required this.entries,
    this.daysToShow,
    this.startDate,
    this.currentDate,
    this.initialYear,
    this.onDayTap,
  });

  static const cell = 13.0;
  static const gap = 3.0;
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  State<GreenGrid> createState() => _GreenGridState();
}

class _GreenGridState extends State<GreenGrid> {
  late int _selectedYear;

  DateTime get _today {
    final now = widget.currentDate ?? DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _taskStartDate {
    if (widget.startDate != null) {
      final s = widget.startDate!;
      return DateTime(s.year, s.month, s.day);
    }
    final days = widget.daysToShow ?? 35;
    final weeks = (days / 7).ceil();
    return _today.subtract(
      Duration(days: (_today.weekday - 1) + 7 * (weeks - 1)),
    );
  }

  List<int> get _availableYears {
    final startYear = _taskStartDate.year;
    final endYear = _today.year;
    if (startYear >= endYear) {
      return [startYear];
    }
    return [for (int y = startYear; y <= endYear; y++) y];
  }

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? _today.year;
    if (!_availableYears.contains(_selectedYear)) {
      _selectedYear = _availableYears.last;
    }
  }

  @override
  void didUpdateWidget(covariant GreenGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_availableYears.contains(_selectedYear)) {
      _selectedYear = _availableYears.last;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final taskStartDate = _taskStartDate;
    final selectedYear = _selectedYear;

    DateTime mondayOfFirstWeek;
    if (selectedYear == taskStartDate.year) {
      mondayOfFirstWeek = taskStartDate.subtract(
        Duration(days: taskStartDate.weekday - 1),
      );
    } else {
      final jan1 = DateTime(selectedYear, 1, 1);
      mondayOfFirstWeek = jan1.subtract(Duration(days: jan1.weekday - 1));
    }

    DateTime endOfRange;
    if (selectedYear == today.year) {
      endOfRange = today;
    } else {
      endOfRange = DateTime(selectedYear, 12, 31);
    }

    final daysCount = endOfRange.difference(mondayOfFirstWeek).inDays + 1;
    final weeks = math.max(1, (daysCount / 7).ceil());

    final entryMap = <String, TaskEntryEntity>{};
    for (final e in widget.entries) {
      final key =
          '${e.entryDate.year}-${e.entryDate.month.toString().padLeft(2, '0')}-${e.entryDate.day.toString().padLeft(2, '0')}';
      entryMap[key] = e;
    }

    const h = 7 * (GreenGrid.cell + GreenGrid.gap) - GreenGrid.gap;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year selector at the top of the grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                key: const Key('green_grid_year_selector'),
                value: selectedYear,
                isDense: true,
                icon: Icon(
                  Icons.arrow_drop_down,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                items: _availableYears.map((y) {
                  return DropdownMenuItem<int>(
                    value: y,
                    child: Text('$y'),
                  );
                }).toList(),
                onChanged: (y) {
                  if (y != null) {
                    setState(() => _selectedYear = y);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
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
                      height: GreenGrid.cell,
                      width: 14,
                      child: Center(
                        child: Text(
                          GreenGrid._labels[r],
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
                    if (r < 6) const SizedBox(height: GreenGrid.gap),
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
                        padding: EdgeInsets.only(
                          right: col < weeks - 1 ? GreenGrid.gap : 0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(7, (row) {
                            final date = mondayOfFirstWeek
                                .add(Duration(days: col * 7 + row));

                            // There should NOT be any grid before the task is created,
                            // or after today (in current year), or in another year.
                            final isVisible = !date.isBefore(taskStartDate) &&
                                date.year == selectedYear &&
                                !date.isAfter(today);

                            if (!isVisible) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: row < 6 ? GreenGrid.gap : 0,
                                ),
                                child: const SizedBox(
                                  width: GreenGrid.cell,
                                  height: GreenGrid.cell,
                                ),
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
                              padding: EdgeInsets.only(
                                bottom: row < 6 ? GreenGrid.gap : 0,
                              ),
                              child: GestureDetector(
                                key: ValueKey(
                                  'green_grid_cell_${date.year}_${date.month}_${date.day}',
                                ),
                                onTap: widget.onDayTap != null
                                    ? () => widget.onDayTap!(date)
                                    : null,
                                child: Container(
                                  width: GreenGrid.cell,
                                  height: GreenGrid.cell,
                                  decoration: BoxDecoration(
                                    color: cellColor,
                                    borderRadius: BorderRadius.circular(3),
                                    border: cellBorder ??
                                        (isCurrentDay
                                            ? Border.all(
                                                color: Colors.green.shade800,
                                                width: 1.2,
                                              )
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
        ),
      ],
    );
  }
}
