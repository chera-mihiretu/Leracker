import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../tasks/presentation/task_setup/motion.dart';

abstract final class _GoogleButtonColors {
  static const slate = Color(0xFF1A2234);
  static const emerald = Color(0xFF22C55E);
  static const mint = Color(0xFF86EFAC);
  static const text = Color(0xFFF8FAFC);
}

/// 58dp slate button, 1.5dp emerald border with an animated sheen every 3s,
/// mechanical squash to 0.96 on press, and spinner while authenticating.
class GoogleButton extends StatefulWidget {
  const GoogleButton({
    super.key,
    required this.busy,
    required this.onTap,
    this.mark,
    this.label = 'Continue with Google',
  });

  final bool busy;
  final VoidCallback onTap;
  final Widget? mark;
  final String label;

  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton>
    with SingleTickerProviderStateMixin {
  bool _down = false;
  late final AnimationController _sheen =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1.0,
          duration: Motion.ms(_down ? 90 : 260),
          curve: _down ? Curves.easeOut : Motion.spring,
          child: AnimatedBuilder(
            animation: _sheen,
            builder: (context, child) => CustomPaint(
              foregroundPainter: _SheenBorderPainter(_sheen.value),
              child: child,
            ),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: _GoogleButtonColors.slate,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: Motion.ms(220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: widget.busy
                    ? const SizedBox(
                        key: ValueKey('busy'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: _GoogleButtonColors.emerald,
                        ),
                      )
                    : Row(
                        key: const ValueKey('idle'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.mark ?? const _MarkPlaceholder(),
                          const SizedBox(width: 12),
                          Text(
                            widget.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                              color: _GoogleButtonColors.text,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Neutral stand-in until official Google mark asset is provided via [mark].
class _MarkPlaceholder extends StatelessWidget {
  const _MarkPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Text(
          'G',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _GoogleButtonColors.slate,
          ),
        ),
      );
}

class _SheenBorderPainter extends CustomPainter {
  _SheenBorderPainter(this.t);
  final double t; // 0..1 over 3s; the sheen travels during the first 40%

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _GoogleButtonColors.emerald.withAlpha(110),
    );
    final p = t / 0.4;
    if (p >= 1.0) return;
    final x = -size.width * 0.2 + p * size.width * 1.4;
    final band = Rect.fromLTWH(x - 70, 0, 140, size.height);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          colors: [
            _GoogleButtonColors.mint.withAlpha(0),
            _GoogleButtonColors.mint,
            _GoogleButtonColors.mint.withAlpha(0),
          ],
        ).createShader(band),
    );
  }

  @override
  bool shouldRepaint(covariant _SheenBorderPainter oldDelegate) =>
      oldDelegate.t != t;
}
