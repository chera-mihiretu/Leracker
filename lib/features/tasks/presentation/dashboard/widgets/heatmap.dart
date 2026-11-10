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
    this.weeks = 26,
  });

  final TaskItem task;
  final void Function(DateTime day) onCellTap;

  /// Increment to play the "today" bloom (after a one-tap check).
  final int bloomTick;

  /// Columns of history. 13 ≈ 90 days; the default scrolls back ~6 months.
  final int weeks;

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

  @override
  void initState() {
    super.initState();
    // Snap to "today" so the latest progress is visible immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  void didUpdateWidget(covariant Heatmap old) {
    super.didUpdateWidget(old);
    if (widget.bloomTick != old.bloomTick) _bloom.forward(from: 0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pulse.dispose();
    _bloom.dispose();
    super.dispose();
  }

  DateTime get _today => dateOnly(DateTime.now());

  /// Monday of the first column.
  DateTime get _start =>
      addDays(_today, -(_today.weekday - 1) - 7 * (widget.weeks - 1));

  void _tap(Offset p) {
    final col = (p.dx / Heatmap.step).floor();
    final row = (p.dy / Heatmap.step).floor();
    if (col < 0 || col >= widget.weeks || row < 0 || row > 6) return;
    final day = addDays(_start, col * 7 + row);
    if (day.isAfter(_today)) return;
    widget.onCellTap(day);
  }

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final w = widget.weeks * Heatmap.step - Heatmap.gap;
    const h = 7 * Heatmap.step - Heatmap.gap;
    return SizedBox(
      height: h,
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
                start: _start,
                today: _today,
                weeks: widget.weeks,
                palette: p,
                pulse: _pulse.value,
                bloom: _bloom.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.task,
    required this.start,
    required this.today,
    required this.weeks,
    required this.palette,
    required this.pulse,
    required this.bloom,
  });

  final TaskItem task;
  final DateTime start, today;
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

/// Small sheet opened by tapping a cell: date, status, Done / Missed / Reset.
Future<void> showCellSheet({
  required BuildContext context,
  required TaskItem task,
  required DateTime day,
  required void Function(EntryStatus? status) onSet,
}) {
  final p = DashTheme.of(context);
  final state = task.cellState(day, dateOnly(DateTime.now()));
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
              Text(longDate(day),
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 4),
              Text('Status: $label',
                  style: TextStyle(fontSize: 14, color: p.textMuted)),
              const SizedBox(height: 18),
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
