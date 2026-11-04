// Page 3 — Start time & daily window.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion.dart';
import '../task_draft.dart';
import '../widgets/entrance.dart';

class TimePage extends StatefulWidget {
  const TimePage({super.key, required this.draft});
  final TaskDraft draft;

  @override
  State<TimePage> createState() => _TimePageState();
}

class _TimePageState extends State<TimePage> {
  static const _presets = <(DayWindow, String, int)>[
    (DayWindow.morning, 'Morning', 8 * 60),
    (DayWindow.afternoon, 'Afternoon', 13 * 60),
    (DayWindow.evening, 'Evening', 19 * 60),
  ];

  bool _up = true; // direction the drum digits roll
  double _drag = 0;
  Timer? _inertia;

  void _setMinutes(int m) {
    final next = m % (24 * 60);
    final cur = widget.draft.minutes;
    if (next == cur) return;
    setState(() => _up = (next > cur && next - cur < 720) || cur - next > 720);
    HapticFeedback.selectionClick();
    widget.draft.update(() => widget.draft.minutes = next);
  }

  void _step(int delta) => _setMinutes(widget.draft.minutes + delta);

  // Vertical drag on the drum: every 18px = 5 min. Fling = inertial roll.
  void _onDragUpdate(DragUpdateDetails d) {
    _inertia?.cancel();
    _drag += d.delta.dy;
    while (_drag.abs() >= 18) {
      _step(_drag < 0 ? 5 : -5);
      _drag += _drag < 0 ? 18 : -18;
    }
  }

  void _onDragEnd(DragEndDetails d) {
    _drag = 0;
    final v = d.velocity.pixelsPerSecond.dy;
    var steps = (v.abs() / 350).floor().clamp(0, 14);
    if (steps == 0) return;
    final dir = v < 0 ? 5 : -5;
    var interval = 40;
    void tick() {
      if (!mounted || steps <= 0) return;
      _step(dir);
      steps--;
      interval = (interval * 1.22).round(); // decelerate
      _inertia = Timer(Motion.ms(interval), tick);
    }

    tick();
  }

  @override
  void dispose() {
    _inertia?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return AnimatedBuilder(
      animation: draft,
      builder: (context, _) {
        final phase = draft.window.index.toDouble();
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            const PageHeader(title: 'When is your ideal time to do this?'),
            const SizedBox(height: 20),
            Entrance(
              delay: Motion.ms(80),
              child: Center(child: CelestialIcon(phase: phase, size: 180)),
            ),
            const SizedBox(height: 16),
            Entrance(
              delay: Motion.ms(140),
              child: Row(
                children: [
                  for (final p in _presets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _WindowButton(
                          label: p.$2,
                          selected: draft.window == p.$1,
                          onTap: () => _setMinutes(p.$3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Entrance(
              delay: Motion.ms(200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundIcon(icon: Icons.remove_rounded, onTap: () => _step(-15)),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: TimeDrum(text: draft.timeLabel, up: _up),
                  ),
                  const SizedBox(width: 16),
                  _RoundIcon(icon: Icons.add_rounded, onTap: () => _step(15)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text('Drag the clock up or down',
                  style: TextStyle(fontSize: 12, color: PT.textFaint)),
            ),
          ],
        );
      },
    );
  }
}

class _WindowButton extends StatelessWidget {
  const _WindowButton(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Squash(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.ms(200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? fade(PT.emerald, 0.12) : PT.slate,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? PT.emerald : PT.inactive),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? PT.text : PT.textMuted)),
        ),
      );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Squash(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: PT.inactive),
          ),
          child: Icon(icon, color: PT.textMuted),
        ),
      );
}

// ── Split-flap style time drum ───────────────────────────────────────────

class TimeDrum extends StatelessWidget {
  const TimeDrum({super.key, required this.text, required this.up});
  final String text; // "HH:MM"
  final bool up;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < text.length; i++)
          text[i] == ':'
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(':',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: PT.textMuted)),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _FlapDigit(digit: text[i], up: up),
                ),
      ],
    );
  }
}

class _FlapDigit extends StatelessWidget {
  const _FlapDigit({required this.digit, required this.up});
  final String digit;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 60,
      decoration: BoxDecoration(
        color: PT.slate,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSwitcher(
              duration: Motion.ms(300),
              switchInCurve: Motion.decel,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey(digit);
                final dir = up ? 1.0 : -1.0;
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, incoming ? dir : -dir),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
              child: Text(
                digit,
                key: ValueKey(digit),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: PT.text,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            // The split-flap hinge line.
            Container(height: 1.5, color: fade(PT.obsidian, 0.8)),
          ],
        ),
      ),
    );
  }
}

// ── Celestial icon: sunrise → noon sun → crescent moon ───────────────────

/// [phase]: 0 = morning, 1 = afternoon, 2 = evening. Changing it morphs the
/// shape over 350ms; on first build the morning sun rises from the horizon.
class CelestialIcon extends StatefulWidget {
  const CelestialIcon({super.key, required this.phase, this.size = 160});
  final double phase;
  final double size;

  @override
  State<CelestialIcon> createState() => _CelestialIconState();
}

class _CelestialIconState extends State<CelestialIcon>
    with TickerProviderStateMixin {
  late final AnimationController _morph =
      AnimationController(vsync: this, duration: Motion.ms(350));
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))
        ..repeat();
  late double _from = widget.phase - (widget.phase == 0 ? 0.7 : 0.0);
  late double _to = widget.phase;

  @override
  void initState() {
    super.initState();
    if (_from != _to) {
      _morph.duration = Motion.ms(700);
      _morph.forward(from: 0);
    } else {
      _morph.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant CelestialIcon old) {
    super.didUpdateWidget(old);
    if (old.phase != widget.phase) {
      _from = _current;
      _to = widget.phase;
      _morph.duration = Motion.ms(350);
      _morph.forward(from: 0);
    }
  }

  double get _current =>
      lerpDouble(_from, _to, Motion.decel.transform(_morph.value))!;

  @override
  void dispose() {
    _morph.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 0.75,
      child: AnimatedBuilder(
        animation: Listenable.merge([_morph, _ambient]),
        builder: (context, _) => CustomPaint(
          painter: _CelestialPainter(phase: _current, ambient: _ambient.value),
        ),
      ),
    );
  }
}

class _CelestialPainter extends CustomPainter {
  _CelestialPainter({required this.phase, required this.ambient});
  final double phase; // may dip below 0 while rising
  final double ambient; // 0..1 looping

  static const _sunrise = Color(0xFFF59E0B);
  static const _noon = Color(0xFFFBBF24);
  static const _moon = Color(0xFFE2E8F0);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final horizon = h * 0.82;
    final a = phase.clamp(-1.0, 1.0); // morning → noon part
    final q = (phase - 1).clamp(0.0, 1.0); // noon → moon part

    final cx = w / 2;
    final cy = phase <= 1
        ? lerpDouble(h * 0.70, h * 0.36, a)!
        : lerpDouble(h * 0.36, h * 0.40, q)!;
    final r = phase <= 1
        ? lerpDouble(h * 0.17, h * 0.21, a.clamp(0.0, 1.0))!
        : lerpDouble(h * 0.21, h * 0.20, q)!;
    final body = phase <= 1
        ? Color.lerp(_sunrise, _noon, a.clamp(0.0, 1.0))!
        : Color.lerp(_noon, _moon, q)!;

    // Stars (fade in for evening, twinkle).
    if (q > 0) {
      const stars = [
        Offset(0.18, 0.22), Offset(0.80, 0.16), Offset(0.88, 0.48),
        Offset(0.12, 0.55), Offset(0.68, 0.06),
      ];
      final sp = Paint()..color = _moon;
      for (var i = 0; i < stars.length; i++) {
        final tw = 0.5 + 0.5 * math.sin(2 * math.pi * (ambient * 6 + i * 0.37));
        sp.color = fade(_moon, q * (0.35 + 0.65 * tw));
        _drawStar(canvas, Offset(stars[i].dx * w, stars[i].dy * h),
            h * 0.025 * (0.7 + 0.3 * tw), sp);
      }
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, w, horizon));

    // Rays: strongest at noon, rotate slowly, vanish into the moon.
    final rayAlpha = phase <= 1 ? 0.45 + 0.55 * a.clamp(0.0, 1.0) : 1 - q;
    if (rayAlpha > 0.01) {
      final rays = Paint()
        ..color = fade(body, rayAlpha)
        ..strokeWidth = h * 0.028
        ..strokeCap = StrokeCap.round;
      final rot = ambient * 2 * math.pi * (phase >= 0.5 ? 1 : 0.3);
      for (var i = 0; i < 8; i++) {
        final ang = rot + i * math.pi / 4;
        final dir = Offset(math.cos(ang), math.sin(ang));
        canvas.drawLine(Offset(cx, cy) + dir * r * 1.4,
            Offset(cx, cy) + dir * r * (1.65 + 0.1 * a.clamp(0.0, 1.0)), rays);
      }
    }

    // Body, with a crescent cut-out growing in for the moon.
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = body);
    if (q > 0) {
      canvas.drawCircle(
        Offset(cx + r * 0.55 * q, cy - r * 0.30 * q),
        r * 0.88 * q,
        Paint()..blendMode = BlendMode.clear,
      );
    }
    canvas.restore();
    canvas.restore();

    // Horizon line.
    canvas.drawLine(
      Offset(w * 0.12, horizon),
      Offset(w * 0.88, horizon),
      Paint()
        ..color = PT.inactive
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawStar(Canvas c, Offset o, double s, Paint p) {
    final path = Path()
      ..moveTo(o.dx, o.dy - s * 2)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + s * 2, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + s * 2)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - s * 2, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - s * 2)
      ..close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _CelestialPainter o) =>
      o.phase != phase || o.ambient != ambient;
}
