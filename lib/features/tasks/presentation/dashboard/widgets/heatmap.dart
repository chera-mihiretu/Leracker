// Horizontal contribution heatmap: 7 rows (Mon–Sun) × N week columns,
// ending on today. 13px cells, 3px radius, 3px spacing.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../task_setup/motion.dart';
import '../dash_theme.dart';
import '../task_item.dart';

class Heatmap extends StatefulWidget {
  const Heatmap({
    super.key,
    required this.task,
    required this.onCellTap,
    this.bloomTick = 0,
    this.weeks,
    this.currentDate,
    this.initialYear,
  });

  final TaskItem task;
  final void Function(DateTime day) onCellTap;

  /// Increment to play the "today" bloom (after a one-tap check).
  final int bloomTick;

  /// Optional fixed columns override (defaults to weeks calculated from start date to today).
  final int? weeks;

  final DateTime? currentDate;
  final int? initialYear;

  static const cell = 13.0, gap = 3.0, step = cell + gap;

  @override
  State<Heatmap> createState() => _HeatmapState();
}

class _HeatmapState extends State<Heatmap> with TickerProviderStateMixin {
  final _scroll = ScrollController();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat(reverse: true);
  late final AnimationController _bloom =
      AnimationController(vsync: this, duration: Motion.ms(650), value: 1);

  late int _selectedYear;

  DateTime get _today => dateOnly(widget.currentDate ?? DateTime.now());
  DateTime get _taskStartDate => dateOnly(widget.task.createdAt);

  List<int> get _availableYears {
    final startYear = _taskStartDate.year;
    final endYear = _today.year;
    if (startYear >= endYear) return [startYear];
    return [for (var y = startYear; y <= endYear; y++) y];
  }

  DateTime get _mondayOfStartWeek {
    if (_selectedYear == _taskStartDate.year) {
      return addDays(_taskStartDate, -(_taskStartDate.weekday - 1));
    }
    final jan1 = DateTime(_selectedYear, 1, 1);
    return addDays(jan1, -(jan1.weekday - 1));
  }

  DateTime get _endOfRange {
    if (_selectedYear == _today.year) {
      return _today;
    }
    return DateTime(_selectedYear, 12, 31);
  }

  int get _calculatedWeeks {
    if (widget.weeks != null) return widget.weeks!;
    final daysCount = _endOfRange.difference(_mondayOfStartWeek).inDays + 1;
    return math.max(1, (daysCount / 7).ceil());
  }

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? _today.year;
    if (!_availableYears.contains(_selectedYear)) {
      _selectedYear = _availableYears.last;
    }
    // Snap to "today" so the latest progress is visible immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void didUpdateWidget(covariant Heatmap old) {
    super.didUpdateWidget(old);
    if (widget.bloomTick != old.bloomTick) _bloom.forward(from: 0);
    if (!_availableYears.contains(_selectedYear)) {
      _selectedYear = _availableYears.last;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pulse.dispose();
    _bloom.dispose();
    super.dispose();
  }

  void _tap(Offset p) {
    final col = (p.dx / Heatmap.step).floor();
    final row = (p.dy / Heatmap.step).floor();
    final weeks = _calculatedWeeks;
    if (col < 0 || col >= weeks || row < 0 || row > 6) return;
    final day = addDays(_mondayOfStartWeek, col * 7 + row);
    if (day.isBefore(_taskStartDate) ||
        day.year != _selectedYear ||
        day.isAfter(_today)) {
      return;
    }
    widget.onCellTap(day);
  }

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final weeks = _calculatedWeeks;
    final w = weeks * Heatmap.step - Heatmap.gap;
    const h = 7 * Heatmap.step - Heatmap.gap;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                key: const Key('heatmap_year_selector'),
                value: _selectedYear,
                isDense: true,
                icon: Icon(Icons.arrow_drop_down, size: 18, color: p.textMuted),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: p.text,
                ),
                dropdownColor: p.card,
                items: _availableYears.map((y) {
                  return DropdownMenuItem<int>(
                    value: y,
                    child: Text('$y'),
                  );
                }).toList(),
                onChanged: (y) {
                  if (y != null) {
                    setState(() {
                      _selectedYear = y;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scroll.hasClients) {
                          _scroll.jumpTo(_scroll.position.maxScrollExtent);
                        }
                      });
                    });
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
              _DayLabelsColumn(palette: p),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: GestureDetector(
                    onTapUp: (d) => _tap(d.localPosition),
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_pulse, _bloom]),
                      builder: (context, _) => CustomPaint(
                        size: Size(w, h),
                        painter: _HeatmapPainter(
                          task: widget.task,
                          start: _mondayOfStartWeek,
                          today: _today,
                          taskStartDate: _taskStartDate,
                          selectedYear: _selectedYear,
                          weeks: weeks,
                          palette: p,
                          pulse: _pulse.value,
                          bloom: _bloom.value,
                        ),
                      ),
                    ),
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

class _DayLabelsColumn extends StatelessWidget {
  const _DayLabelsColumn({required this.palette});
  final DashPalette palette;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < 7; i++) ...[
          SizedBox(
            height: Heatmap.cell,
            width: 12,
            child: Center(
              child: Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: palette.textFaint,
                  height: 1.0,
                ),
              ),
            ),
          ),
          if (i < 6) const SizedBox(height: Heatmap.gap),
        ],
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.task,
    required this.start,
    required this.today,
    required this.taskStartDate,
    required this.selectedYear,
    required this.weeks,
    required this.palette,
    required this.pulse,
    required this.bloom,
  });

  final TaskItem task;
  final DateTime start, today, taskStartDate;
  final int selectedYear;
  final int weeks;
  final DashPalette palette;
  final double pulse, bloom;

  @override
  void paint(Canvas canvas, Size size) {
    const c = Heatmap.cell, st = Heatmap.step;
    final accent = task.gridColor;
    final fill = Paint();
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color.lerp(accent, Colors.white, 0.35)!.withAlpha(90);

    for (var col = 0; col < weeks; col++) {
      for (var row = 0; row < 7; row++) {
        final day = addDays(start, col * 7 + row);
        // There should NOT be any grid cell before task was created,
        // or outside the selected year, or after today.
        if (day.isBefore(taskStartDate) ||
            day.year != selectedYear ||
            day.isAfter(today)) {
          continue;
        }

        final state = task.cellState(day, today);
        if (state == CellState.future) continue;
        final rect = Rect.fromLTWH(col * st, row * st, c, c);
        final isToday = day == today;

        switch (state) {
          case CellState.done:
            var r = rect;
            if (isToday && bloom < 1) {
              // Bloom 0.6× → 1.0× with a spring, plus an expanding burst.
              final s = 0.6 + 0.4 * Motion.spring.transform(bloom);
              r = Rect.fromCenter(center: rect.center, width: c * s, height: c * s);
              final burst = Curves.easeOut.transform(bloom);
              canvas.drawCircle(
                rect.center,
                c * (0.6 + 1.6 * burst),
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2 * (1 - burst) + 0.5
                  ..color = accent.withAlpha((180 * (1 - burst)).round()),
              );
            }
            fill.color = accent;
            final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
            canvas.drawRRect(rr, fill);
            canvas.drawRRect(rr.deflate(0.5), glow); // subtle inner glow
          case CellState.missed:
            fill.color = palette.missed;
            canvas.drawRRect(
                RRect.fromRectAndRadius(rect, const Radius.circular(3)), fill);
          case CellState.rest:
            fill.color = palette.rest;
            canvas.drawRRect(
                RRect.fromRectAndRadius(rect, const Radius.circular(3)), fill);
          case CellState.pending:
            // Accent border with a softly pulsing interior.
            fill.color = accent.withAlpha((255 * (0.08 + 0.28 * pulse)).round());
            final rr = RRect.fromRectAndRadius(rect, const Radius.circular(3));
            canvas.drawRRect(rr, fill);
            canvas.drawRRect(
              rr.deflate(0.75),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5
                ..color = accent,
            );
          case CellState.future:
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HeatmapPainter o) => true;
}

/// Small sheet opened by tapping a cell: date, status, and Done / Missed / Reset (for today only).
Future<void> showCellSheet({
  required BuildContext context,
  required TaskItem task,
  required DateTime day,
  required void Function(EntryStatus? status) onSet,
}) {
  final p = DashTheme.of(context);
  final today = dateOnly(DateTime.now());
  final isPast = dateOnly(day).isBefore(today);
  final state = task.cellState(day, today);
  final label = switch (state) {
    CellState.done => 'Completed',
    CellState.missed => 'Missed',
    CellState.pending => 'Due today',
    _ => 'Not scheduled',
  };
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) {
      Widget option(String text, IconData icon, EntryStatus? s, bool selected) {
        return Expanded(
          child: GestureDetector(
            onTap: () {
              onSet(s);
              Navigator.of(ctx).pop();
            },
            child: AnimatedContainer(
              duration: Motion.ms(200),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected ? task.gridColor.withAlpha(36) : p.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? task.gridColor : p.border),
              ),
              child: Column(
                children: [
                  Icon(icon, color: selected ? task.gridColor : p.textMuted),
                  const SizedBox(height: 4),
                  Text(text,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? p.text : p.textMuted)),
                ],
              ),
            ),
          ),
        );
      }

      final s = task.statusOn(day);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: p.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(task.name,
                  style: TextStyle(fontSize: 13, color: p.textMuted)),
              const SizedBox(height: 2),
              Text(weekdayLongDate(day),
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 4),
              Text('Status: $label',
                  style: TextStyle(fontSize: 14, color: p.textMuted)),
              const SizedBox(height: 18),
              if (isPast)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: p.isDark ? p.bg : p.rest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state == CellState.done
                            ? Icons.check_circle_rounded
                            : state == CellState.missed
                                ? Icons.cancel_rounded
                                : Icons.info_outline_rounded,
                        size: 20,
                        color: state == CellState.done
                            ? DashPalette.emerald
                            : state == CellState.missed
                                ? p.missed
                                : p.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Past entries cannot be edited',
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (!task.isDueOn(day))
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: p.isDark ? p.bg : p.rest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 20,
                        color: p.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'This task is not scheduled for today',
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (!task.isDueOn(day))
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: p.isDark ? p.bg : p.rest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 20,
                        color: p.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: p.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'This task is not scheduled for today',
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    option('Done', Icons.check_rounded, EntryStatus.done,
                        s == EntryStatus.done),
                    const SizedBox(width: 10),
                    option('Missed', Icons.close_rounded, EntryStatus.missed,
                        s == EntryStatus.missed),
                    const SizedBox(width: 10),
                    option('Reset', Icons.refresh_rounded, null, false),
                  ],
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// 7-day compact dot strip (used by the hero card).
class WeekDots extends StatelessWidget {
  const WeekDots({super.key, required this.values});
  final List<double?> values; // oldest → today

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final today = dateOnly(DateTime.now());
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          Column(
            children: [
              Text(
                'MTWTFSS'[addDays(today, i - 6).weekday - 1],
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: i == 6 ? p.text : p.textFaint),
              ),
              const SizedBox(height: 6),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: values[i] == null
                      ? p.rest
                      : Color.lerp(p.missed, DashPalette.emerald,
                          math.max(0.0, values[i]!)),
                  border: i == 6
                      ? Border.all(color: DashPalette.emerald, width: 1.5)
                      : null,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
