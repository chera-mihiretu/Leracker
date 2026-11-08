// Daily Hero Pulse: completion ring, streak, consistency, 7-day dots.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../task_setup/motion.dart';
import '../dash_theme.dart';
import '../dashboard_store.dart';
import 'heatmap.dart';

class HeroPulse extends StatelessWidget {
  const HeroPulse({super.key, required this.store});
  final DashboardStore store;

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final total = store.dueToday.length;
    final done = store.doneToday;
    final ratio = total == 0 ? 0.0 : done / total;
    final headline = total == 0
        ? 'Nothing due today'
        : done == total
            ? 'All done for today'
            : ratio >= 0.5
                ? 'You\'re on track today'
                : 'Let\'s build momentum';

    return AnimatedContainer(
      duration: Motion.ms(300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: ratio),
                duration: Motion.ms(700),
                curve: Motion.decel,
                builder: (context, v, _) => SizedBox.square(
                  dimension: 80,
                  child: CustomPaint(
                    painter: _RingPainter(
                        progress: v, segments: total, track: p.missed),
                    child: Center(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: '$done',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: p.text)),
                          TextSpan(
                              text: '/$total',
                              style: TextStyle(fontSize: 14, color: p.textMuted)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: Motion.ms(250),
                      child: Text(
                        headline,
                        key: ValueKey(headline),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            color: p.text),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$done of $total done today',
                        style: TextStyle(fontSize: 13, color: p.textMuted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Stat(
                          icon: Icons.insights_rounded,
                          text: '${(store.consistency * 100).round()}% consistency',
                          color: p.textMuted,
                          bg: p.isDark ? p.bg : p.rest,
                        ),
                        if (store.bestStreak > 0)
                          _Stat(
                            icon: Icons.local_fire_department_rounded,
                            text: '${store.bestStreak}-day streak',
                            color: DashPalette.emerald,
                            bg: DashPalette.emerald.withAlpha(30),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: p.border),
          const SizedBox(height: 14),
          WeekDots(values: store.last7),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.icon,
      required this.text,
      required this.color,
      required this.bg});
  final IconData icon;
  final String text;
  final Color color, bg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: color)),
        ]),
      );
}

/// Segmented ring (one segment per due task, continuous above 12).
class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.segments, required this.track});
  final double progress;
  final int segments;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    final on = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = DashPalette.emerald;

    if (segments <= 1 || segments > 12) {
      canvas.drawArc(arcRect, 0, 2 * math.pi, false, base);
      if (progress > 0) {
        canvas.drawArc(arcRect, -math.pi / 2, 2 * math.pi * progress, false, on);
      }
      return;
    }
    const gapAngle = 0.28;
    final seg = 2 * math.pi / segments;
    final filled = progress * segments;
    for (var i = 0; i < segments; i++) {
      final start = -math.pi / 2 + i * seg + gapAngle / 2;
      final sweep = seg - gapAngle;
      canvas.drawArc(arcRect, start, sweep, false, base);
      final f = (filled - i).clamp(0.0, 1.0);
      if (f > 0) canvas.drawArc(arcRect, start, sweep * f, false, on);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) =>
      o.progress != progress || o.segments != segments || o.track != track;
}
