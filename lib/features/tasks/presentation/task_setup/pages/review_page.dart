// Page 6 — Review & final confirmation.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion.dart';
import '../task_draft.dart';
import '../widgets/entrance.dart';
import '../widgets/task_card.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key, required this.draft, required this.onCreate});
  final TaskDraft draft;

  /// Called after the confetti has burst. Navigate to the task list here.
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: draft,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(title: 'Accountability rules'),
            const SizedBox(height: 24),
            // Card drops in with gravity: -30dp → 0 with overshoot (0–400ms).
            Entrance(
              duration: Motion.ms(400),
              offsetY: -30,
              curve: Motion.spring,
              child: TaskCard(draft: draft),
            ),
            const SizedBox(height: 20),
            Entrance(
              delay: Motion.ms(150),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: PT.slate,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Morning review',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: PT.text)),
                          SizedBox(height: 2),
                          Text('Confirm yesterday\'s tile each morning',
                              style: TextStyle(
                                  fontSize: 13, color: PT.textMuted)),
                        ],
                      ),
                    ),
                    FluidToggle(
                      value: draft.morningReview,
                      onChanged: (v) =>
                          draft.update(() => draft.morningReview = v),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Entrance(
              delay: Motion.ms(250),
              child: CelebrateButton(
                label: 'Create habit and start grid',
                color: draft.color,
                onCelebrated: onCreate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fluid toggle ──────────────────────────────────────────────────────────

class FluidToggle extends StatefulWidget {
  const FluidToggle({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<FluidToggle> createState() => _FluidToggleState();
}

class _FluidToggleState extends State<FluidToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Motion.ms(300), value: widget.value ? 1 : 0);

  @override
  void didUpdateWidget(covariant FluidToggle old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      widget.value ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const w = 54.0, h = 32.0, thumb = 24.0, pad = 4.0;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onChanged(!widget.value);
      },
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Motion.spring.transform(_c.value);
          final lin = _c.value;
          // Thumb stretches mid-travel for a liquid feel.
          final stretch = 10 * math.sin(math.pi * lin);
          final travel = w - thumb - pad * 2;
          return Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: Color.lerp(PT.inactive, PT.emerald, lin.clamp(0.0, 1.0)),
              borderRadius: BorderRadius.circular(h / 2),
              boxShadow: [
                BoxShadow(color: fade(PT.emerald, 0.4 * lin), blurRadius: 12),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: pad + travel * t - (lin < 0.5 ? 0 : stretch),
                  top: pad,
                  child: Container(
                    width: thumb + stretch,
                    height: thumb,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(thumb / 2),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── CTA with shimmer, squash and confetti burst ──────────────────────────

class CelebrateButton extends StatefulWidget {
  const CelebrateButton({
    super.key,
    required this.label,
    required this.onCelebrated,
    this.color = PT.emerald,
  });

  final String label;
  final Color color;
  final VoidCallback onCelebrated;

  @override
  State<CelebrateButton> createState() => _CelebrateButtonState();
}

class _CelebrateButtonState extends State<CelebrateButton>
    with TickerProviderStateMixin {
  // Sheen passes once every 3 seconds.
  late final AnimationController _shimmer =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
  late final AnimationController _burst =
      AnimationController(vsync: this, duration: Motion.ms(1000));
  bool _down = false;
  bool _fired = false;
  late List<_Particle> _particles;

  void _fire() {
    if (_fired) return;
    _fired = true;
    HapticFeedback.mediumImpact();
    final rnd = math.Random();
    final colors = [PT.emerald, PT.jade, PT.mint, widget.color];
    _particles = List.generate(34, (i) {
      final ang = -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.5;
      return _Particle(
        angle: ang,
        speed: 260 + rnd.nextDouble() * 280,
        size: 6 + rnd.nextDouble() * 5,
        spin: (rnd.nextDouble() - 0.5) * 14,
        color: colors[i % colors.length],
      );
    });
    _burst.forward(from: 0);
    Future.delayed(Motion.ms(650), () {
      if (mounted) widget.onCelebrated();
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _down = true),
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) {
            setState(() => _down = false);
            _fire();
          },
          child: AnimatedScale(
            scale: _down ? 0.96 : 1,
            duration: Motion.ms(_down ? 90 : 260),
            curve: _down ? Curves.easeOut : Motion.spring,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 58,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: widget.color),
                    AnimatedBuilder(
                      animation: _shimmer,
                      builder: (context, _) =>
                          CustomPaint(painter: _SheenPainter(_shimmer.value)),
                    ),
                    Center(
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.color.computeLuminance() > 0.5
                              ? PT.obsidian
                              : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_fired)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (context, _) => CustomPaint(
                  painter: _ConfettiPainter(_particles, _burst.value),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SheenPainter extends CustomPainter {
  _SheenPainter(this.t);
  final double t; // 0..1 over 3s; the sheen crosses during the first 0.3

  @override
  void paint(Canvas canvas, Size size) {
    final p = t / 0.3;
    if (p >= 1) return;
    final x = -size.width * 0.4 + p * size.width * 1.8;
    final rect = Rect.fromLTWH(x - 60, -20, 120, size.height + 40);
    canvas.save();
    canvas.translate(x, size.height / 2);
    canvas.rotate(0.35);
    canvas.translate(-x, -size.height / 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(colors: [
          Colors.white.withAlpha(0),
          Colors.white.withAlpha(70),
          Colors.white.withAlpha(0),
        ]).createShader(rect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SheenPainter o) => o.t != t;
}

class _Particle {
  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
  });
  final double angle, speed, size, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);
  final List<_Particle> particles;
  final double t; // 0..1 over 1s

  @override
  void paint(Canvas canvas, Size size) {
    final origin = size.center(Offset.zero);
    const gravity = 900.0;
    final secs = t;
    final paint = Paint();
    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * secs;
      final dy = math.sin(p.angle) * p.speed * secs + 0.5 * gravity * secs * secs;
      final alpha = (1 - t).clamp(0.0, 1.0);
      paint.color = fade(p.color, alpha);
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * secs);
      final s = p.size * (1 - 0.3 * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s, height: s),
            Radius.circular(s * 0.28)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter o) => o.t != t;
}
