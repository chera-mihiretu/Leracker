// Empty dashboard: a grid that fades from dark to glowing green.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../task_setup/motion.dart';
import '../../task_setup/widgets/entrance.dart';
import '../dash_theme.dart';

class ZeroState extends StatefulWidget {
  const ZeroState({super.key, required this.onCreate});
  final VoidCallback onCreate;

  @override
  State<ZeroState> createState() => _ZeroStateState();
}

class _ZeroStateState extends State<ZeroState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Entrance(
          duration: Motion.ms(500),
          child: SizedBox.square(
            dimension: 150,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _FadeGridPainter(t: _c.value, dim: p.missed),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Entrance(
          delay: Motion.ms(120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Small consistent steps compound into extraordinary results.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: p.text,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Entrance(
          delay: Motion.ms(220),
          child: Squash(
            pressedScale: 0.96,
            onTap: widget.onCreate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              decoration: BoxDecoration(
                color: DashPalette.emerald,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: DashPalette.emerald.withAlpha(110), blurRadius: 24),
                ],
              ),
              child: const Text('Create your first habit',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}

class _FadeGridPainter extends CustomPainter {
  _FadeGridPainter({required this.t, required this.dim});
  final double t;
  final Color dim;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 5;
    final gap = size.width * 0.05;
    final cell = (size.width - gap * (n - 1)) / n;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        // Diagonal fade dark → green, with a slow light wave moving across.
        final diag = (r + c) / (2 * (n - 1));
        final wave = 0.5 + 0.5 * math.sin(2 * math.pi * (t - diag * 0.6));
        final v = (diag * 0.8 + wave * 0.25).clamp(0.0, 1.0);
        final color = Color.lerp(dim, DashPalette.emerald, v)!;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(c * (cell + gap), r * (cell + gap), cell, cell),
          Radius.circular(cell * 0.24),
        );
        if (v > 0.7) {
          canvas.drawRRect(
              rect,
              Paint()
                ..color = DashPalette.emerald.withAlpha(((v - 0.7) * 300).round())
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.3));
        }
        canvas.drawRRect(rect, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FadeGridPainter o) => o.t != t || o.dim != dim;
}
