// The core item: header row (title, schedule, streak, quick check) + heatmap.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../task_setup/motion.dart';
import '../dash_theme.dart';
import '../dashboard_store.dart';
import '../task_item.dart';
import 'heatmap.dart';

class DashTaskCard extends StatefulWidget {
  const DashTaskCard({
    super.key,
    required this.task,
    required this.store,
    this.currentDate,
  });
  final TaskItem task;
  final DashboardStore store;
  final DateTime? currentDate;

  @override
  State<DashTaskCard> createState() => _DashTaskCardState();
}

class _DashTaskCardState extends State<DashTaskCard> {
  int _bloom = 0;

  void _check() {
    final t = widget.task;
    if (!t.isDueToday) return;
    final willComplete = !t.isCompletedToday;
    willComplete ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick();
    widget.store.toggleToday(t);
    if (willComplete) setState(() => _bloom++);
  }

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final t = widget.task;
    return AnimatedContainer(
      duration: Motion.ms(300),
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: p.text),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          dot: t.gridColor,
                          text: [t.scheduleLabel, if (t.timeLabel != null) t.timeLabel!]
                              .join(' · '),
                          color: p.textMuted,
                          bg: p.isDark ? p.bg : p.rest,
                        ),
                        if (t.currentStreak > 0)
                          _Pill(
                            icon: Icons.local_fire_department_rounded,
                            text: '${t.currentStreak}${t.streakUnit}',
                            color: t.gridColor,
                            bg: t.gridColor.withAlpha(30),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              QuickCheck(
                color: t.gridColor,
                checked: t.isCompletedToday,
                enabled: t.isDueToday,
                onTap: _check,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Heatmap(
            task: t,
            bloomTick: _bloom,
            currentDate: widget.currentDate,
            onCellTap: (day) => showCellSheet(
              context: context,
              task: t,
              day: day,
              onSet: (s) => widget.store.setStatus(t, day, s),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    required this.bg,
    this.dot,
    this.icon,
  });
  final String text;
  final Color color, bg;
  final Color? dot;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
            ],
            Text(text,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      );
}

/// Circular one-tap checkbox: outlined ring → filled with a spring pop.
class QuickCheck extends StatefulWidget {
  const QuickCheck({
    super.key,
    required this.color,
    required this.checked,
    required this.enabled,
    required this.onTap,
  });
  final Color color;
  final bool checked, enabled;
  final VoidCallback onTap;

  @override
  State<QuickCheck> createState() => _QuickCheckState();
}

class _QuickCheckState extends State<QuickCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: Motion.ms(360), value: 1);
  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35),
    TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Motion.spring)),
        weight: 65),
  ]);

  @override
  void didUpdateWidget(covariant QuickCheck old) {
    super.didUpdateWidget(old);
    if (widget.checked && !old.checked) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final c = widget.color;
    final onColor = c.computeLuminance() > 0.5 ? const Color(0xFF0F172A) : Colors.white;
    return Semantics(
      button: true,
      checked: widget.checked,
      label: widget.enabled ? 'Mark done today' : 'Not scheduled today',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pop,
          builder: (context, child) =>
              Transform.scale(scale: _scale.transform(_pop.value), child: child),
          child: AnimatedContainer(
            duration: Motion.ms(220),
            curve: Curves.easeOut,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.checked ? c : Colors.transparent,
              border: Border.all(
                color: widget.checked
                    ? c
                    : widget.enabled
                        ? c.withAlpha(200)
                        : p.border,
                width: 2,
              ),
              boxShadow: [
                if (widget.checked) BoxShadow(color: c.withAlpha(90), blurRadius: 12),
              ],
            ),
            child: AnimatedScale(
              scale: widget.checked ? 1 : 0,
              duration: Motion.ms(260),
              curve: Motion.spring,
              child: Icon(Icons.check_rounded, size: 20, color: onColor),
            ),
          ),
        ),
      ),
    );
  }
}
