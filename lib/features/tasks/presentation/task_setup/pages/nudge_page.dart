// Page 4 — Notification budget & accountability reminders.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion.dart';
import '../task_draft.dart';
import '../widgets/entrance.dart';

class NudgePage extends StatelessWidget {
  const NudgePage({super.key, required this.draft});
  final TaskDraft draft;

  static const _levels = <(String, String)>[
    ('Silent', 'No reminders. Just you and the grid.'),
    ('Single reminder', 'One friendly ding at your start time.'),
    ('Gentle follow-up', 'A second nudge if you haven\'t checked in.'),
    ('High accountability', 'Persistent nudges until it\'s done.'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: draft,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          const PageHeader(
              title: 'How many nudges do you need before checking in?'),
          const SizedBox(height: 28),
          Entrance(
            delay: Motion.ms(80),
            child: Center(child: BellIndicator(level: draft.nudges, size: 170)),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: Motion.ms(220),
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.2), end: Offset.zero)
                    .animate(a),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(draft.nudges),
              children: [
                Text(_levels[draft.nudges].$1,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: PT.text)),
                const SizedBox(height: 4),
                Text(_levels[draft.nudges].$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: PT.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Entrance(
            delay: Motion.ms(160),
            child: SlidingStepper(
              count: 4,
              value: draft.nudges,
              onChanged: (v) => draft.update(() => draft.nudges = v),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4-state bell ──────────────────────────────────────────────────────────

class BellIndicator extends StatefulWidget {
  const BellIndicator({super.key, required this.level, this.size = 160});
  final int level; // 0..3
  final double size;

  @override
  State<BellIndicator> createState() => _BellIndicatorState();
}

class _BellIndicatorState extends State<BellIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Motion.ms(1000));
  Timer? _loop;

  @override
  void initState() {
    super.initState();
    _play();
  }

  @override
  void didUpdateWidget(covariant BellIndicator old) {
    super.didUpdateWidget(old);
    if (old.level != widget.level) _play();
  }

  void _play() {
    _c.forward(from: 0);
    _loop?.cancel();
    // Keep the bell alive: replay its behaviour every 2.8s (not when silent).
    if (widget.level > 0) {
      _loop = Timer.periodic(const Duration(milliseconds: 2800), (_) {
        if (mounted) _c.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _loop?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _BellPainter(level: widget.level, t: _c.value),
        ),
      ),
    );
  }
}

class _BellPainter extends CustomPainter {
  _BellPainter({required this.level, required this.t});
  final int level;
  final double t; // 0..1 over 1000ms

  static const _deg = math.pi / 180;

  double _damp(double x, double end) =>
      x >= end ? 0 : math.pow(1 - x / end, 1.4).toDouble();

  /// Bell rotation (radians) for the current level and time.
  double get _angle {
    switch (level) {
      case 1: // single tilt: -12° → +12° → 0°
        return -12 * _deg * math.sin(2 * math.pi * t / 0.55) * _damp(t, 0.55);
      case 2: // rings twice
        return -14 * _deg * math.sin(2 * math.pi * t * 2 / 0.7) * _damp(t, 0.7);
      case 3: // rapid double shake
        final shake = t < 0.45 ? t / 0.45 : (t < 0.5 ? 1.0 : (t - 0.5) / 0.45);
        if (t >= 0.95 || (t >= 0.45 && t < 0.5)) return 0;
        return 18 * _deg * math.sin(2 * math.pi * shake * 3) *
            math.sin(math.pi * shake);
      default:
        return 0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100; // draw in a 100×100 box
    canvas.save();
    canvas.scale(s);

    const center = Offset(50, 48);
    final silent = level == 0;
    final color = silent ? PT.textFaint : PT.emerald;

    // Soundwave / shockwave rings behind the bell.
    if (level == 2) {
      _ring(canvas, center, ((t - 0.10) / 0.8).clamp(0.0, 1.0), PT.emerald, false);
    } else if (level == 3) {
      for (var i = 0; i < 3; i++) {
        _ring(canvas, center, ((t - 0.05 - i * 0.14) / 0.7).clamp(0.0, 1.0),
            PT.emerald, true);
      }
    }

    // Bell (rotates around its top knob).
    canvas.save();
    const pivot = Offset(50, 14);
    final ang = _angle;
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(ang);
    canvas.translate(-pivot.dx, -pivot.dy);

    final body = Path()
      ..moveTo(50, 18)
      ..cubicTo(34, 18, 27, 31, 27, 46)
      ..lineTo(27, 60)
      ..quadraticBezierTo(27, 66, 20, 71)
      ..lineTo(80, 71)
      ..quadraticBezierTo(73, 66, 73, 60)
      ..lineTo(73, 46)
      ..cubicTo(73, 31, 66, 18, 50, 18)
      ..close();
    final silentFade = silent ? Motion.decel.transform((t / 0.5).clamp(0.0, 1.0)) : 0.0;
    canvas.drawPath(body, Paint()..color = fade(color, 0.12 * (1 - silentFade * 0.5)));
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeJoin = StrokeJoin.round
        ..color = fade(color, 1 - 0.45 * silentFade),
    );
    canvas.drawCircle(const Offset(50, 13), 3.5,
        Paint()..color = fade(color, 1 - 0.45 * silentFade));

    // Clapper swings opposite, with lag.
    canvas.save();
    canvas.translate(50, 71);
    canvas.rotate(-ang * 0.8);
    canvas.drawCircle(const Offset(0, 8), 5.5,
        Paint()..color = fade(color, 1 - 0.45 * silentFade));
    canvas.restore();
    canvas.restore();

    // Silent: a slash draws across the bell.
    if (silent) {
      final p = Motion.decel.transform((t / 0.45).clamp(0.0, 1.0));
      const a = Offset(22, 16), b = Offset(80, 86);
      final end = Offset.lerp(a, b, p)!;
      canvas.drawLine(a, end, Paint()
        ..color = PT.obsidian
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round);
      canvas.drawLine(a, end, Paint()
        ..color = PT.textMuted
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round);
    }
    canvas.restore();
  }

  void _ring(Canvas c, Offset o, double p, Color color, bool glow) {
    if (p <= 0 || p >= 1) return;
    final r = lerpDouble(30, 50, Motion.decel.transform(p))!;
    final alpha = (1 - p) * (glow ? 0.9 : 0.55);
    if (glow) {
      c.drawCircle(o, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = fade(color, alpha * 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
    c.drawCircle(o, r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = glow ? 2.2 : 1.6
      ..color = fade(color, alpha));
  }

  @override
  bool shouldRepaint(covariant _BellPainter o) => o.level != level || o.t != t;
}

// ── Stepper with a glowing pill that stretches while dragged ─────────────

class SlidingStepper extends StatefulWidget {
  const SlidingStepper({
    super.key,
    required this.count,
    required this.value,
    required this.onChanged,
    this.height = 56,
  });

  final int count;
  final int value;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  State<SlidingStepper> createState() => _SlidingStepperState();
}

class _SlidingStepperState extends State<SlidingStepper>
    with SingleTickerProviderStateMixin {
  late double _pos = widget.value.toDouble(); // in index units
  double _stretch = 0; // 0..0.45 extra width while moving
  late final AnimationController _snap =
      AnimationController(vsync: this, duration: Motion.ms(300));
  double _snapFrom = 0, _snapTo = 0, _stretchFrom = 0;

  @override
  void initState() {
    super.initState();
    _snap.addListener(() {
      final t = _snap.value;
      setState(() {
        _pos = lerpDouble(_snapFrom, _snapTo, Motion.spring.transform(t))!;
        // Stretch peaks mid-travel then relaxes as it snaps.
        final travel = (_snapTo - _snapFrom).abs();
        _stretch = _stretchFrom * (1 - t) +
            math.min(0.35, travel * 0.18) * math.sin(math.pi * t);
      });
    });
  }

  @override
  void didUpdateWidget(covariant SlidingStepper old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_snap.isAnimating && _pos.round() != widget.value) {
      _animateTo(widget.value);
    }
  }

  void _animateTo(int index) {
    _snapFrom = _pos;
    _snapTo = index.toDouble();
    _stretchFrom = _stretch;
    _snap.forward(from: 0);
  }

  void _select(int index) {
    HapticFeedback.selectionClick();
    _animateTo(index);
    if (index != widget.value) widget.onChanged(index);
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final segW = box.maxWidth / widget.count;
      return GestureDetector(
        onTapUp: (d) => _select(
            (d.localPosition.dx / segW).floor().clamp(0, widget.count - 1)),
        onHorizontalDragStart: (_) => _snap.stop(),
        onHorizontalDragUpdate: (d) {
          final before = _pos.round();
          setState(() {
            _pos = (_pos + d.delta.dx / segW).clamp(0.0, widget.count - 1.0);
            _stretch = (d.delta.dx.abs() / segW * 5).clamp(0.0, 0.45);
          });
          if (_pos.round() != before) HapticFeedback.selectionClick();
        },
        onHorizontalDragEnd: (_) => _select(_pos.round()),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: PT.slate,
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
          child: Stack(
            children: [
              // The pill.
              Positioned(
                left: (_pos + 0.5) * segW - segW * (1 + _stretch) / 2 + 4,
                top: 4,
                bottom: 4,
                width: segW * (1 + _stretch) - 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: PT.emerald,
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    boxShadow: [
                      BoxShadow(color: fade(PT.emerald, 0.45), blurRadius: 16),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < widget.count; i++)
                    Expanded(
                      child: Center(
                        child: Text(
                          '$i',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color.lerp(Colors.white, PT.textMuted,
                                (_pos - i).abs().clamp(0.0, 1.0)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
