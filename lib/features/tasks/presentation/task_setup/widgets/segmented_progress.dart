import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../motion.dart';

/// 6-segment progress bar. The newly active segment fills with an elastic
/// "liquid" stretch: 0% → 115% → 100% in 280ms. Going back, it retracts.
class SegmentedProgress extends StatefulWidget {
  const SegmentedProgress({
    super.key,
    required this.step,
    this.count = 6,
    this.height = 6,
  });

  final int step; // 0-based index of the current page
  final int count;
  final double height;

  @override
  State<SegmentedProgress> createState() => _SegmentedProgressState();
}

class _SegmentedProgressState extends State<SegmentedProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: Motion.progress, value: 1);
  bool _forward = true;

  static final Animatable<double> _liquid = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65),
    TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35),
  ]);

  @override
  void didUpdateWidget(covariant SegmentedProgress old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) {
      _forward = widget.step > old.step;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ProgressPainter(
            step: widget.step,
            count: widget.count,
            forward: _forward,
            liquid: _liquid.transform(_c.value),
            retract: 1 - Motion.decel.transform(_c.value),
          ),
        ),
      ),
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.step,
    required this.count,
    required this.forward,
    required this.liquid,
    required this.retract,
  });

  final int step, count;
  final bool forward;
  final double liquid, retract;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 6.0;
    final segW = (size.width - gap * (count - 1)) / count;
    final r = Radius.circular(size.height / 2);
    final track = Paint()..color = PT.inactive;
    final fill = Paint()..color = PT.emerald;

    for (var i = 0; i < count; i++) {
      final x = i * (segW + gap);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, segW, size.height), r),
          track);
    }
    for (var i = 0; i < count; i++) {
      double f;
      if (i < step) {
        f = 1;
      } else if (i == step) {
        f = forward ? liquid : 1;
      } else if (i == step + 1 && !forward) {
        f = retract;
      } else {
        f = 0;
      }
      if (f <= 0.001) continue;
      final x = i * (segW + gap);
      final w = lerpDouble(0, segW, f)!.clamp(size.height, segW * 1.2);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, w, size.height), r),
          fill);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter o) =>
      o.step != step ||
      o.liquid != liquid ||
      o.retract != retract ||
      o.forward != forward;
}
