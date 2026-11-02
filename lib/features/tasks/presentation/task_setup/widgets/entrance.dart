import 'dart:async';

import 'package:flutter/widgets.dart';

import '../motion.dart';

/// Delayed slide / fade / scale entrance. Used for every staggered waterfall.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 250),
    this.offsetY = 16,
    this.offsetX = 0,
    this.fromScale = 1,
    this.curve = Motion.decel,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;
  final double offsetX;
  final double fromScale;
  final Curve curve;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = widget.curve.transform(_c.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(widget.offsetX * (1 - t), widget.offsetY * (1 - t)),
            child: Transform.scale(
              scale: widget.fromScale + (1 - widget.fromScale) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Headline + optional subtitle that slides up 16dp and fades in (0–250ms).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              color: PT.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!,
                style: const TextStyle(fontSize: 15, color: PT.textMuted)),
          ],
        ],
      ),
    );
  }
}

/// Scales to 0.95 on press and springs back to 1.0 on release.
class Squash extends StatefulWidget {
  const Squash({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.95,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  @override
  State<Squash> createState() => _SquashState();
}

class _SquashState extends State<Squash> {
  bool _down = false;

  void _set(bool v) => setState(() => _down = v);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) {
        _set(false);
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: Motion.ms(_down ? 90 : 240),
        curve: _down ? Curves.easeOut : Motion.spring,
        child: widget.child,
      ),
    );
  }
}
