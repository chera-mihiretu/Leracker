import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../motion.dart';

/// Mini heatmap. Cells left of [front] (in column units) show [to], cells to
/// the right still show [from]; cells right at the wavefront get a bump.
/// For a static grid pass the same colour for both and front = 999.
class GridPainter extends CustomPainter {
  GridPainter({
    this.cols = 7,
    this.rows = 5,
    required this.from,
    required this.to,
    this.front = 999,
    this.inactive = PT.inactive,
    this.gapRatio = 0.22,
  });

  final int cols, rows;
  final Color from, to, inactive;
  final double front, gapRatio;

  /// Deterministic "completed" pattern with GitHub-style intensity levels.
  static double? level(int c, int r) {
    final h = (c * 31 + r * 17 + c * r * 7) % 10;
    if (h < 2) return null; // missed day
    return const [0.45, 0.6, 0.75, 0.9, 1.0][h % 5];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = math.min(size.width / (cols + (cols - 1) * gapRatio),
        size.height / (rows + (rows - 1) * gapRatio));
    final gap = cell * gapRatio;
    final gridW = cols * cell + (cols - 1) * gap;
    final gridH = rows * cell + (rows - 1) * gap;
    final ox = (size.width - gridW) / 2, oy = (size.height - gridH) / 2;
    final paint = Paint();

    for (var c = 0; c < cols; c++) {
      for (var r = 0; r < rows; r++) {
        final lv = level(c, r);
        // Slight diagonal skew so the wave reads as radial, not a hard wipe.
        final pos = c + r * 0.12;
        final t = (front - pos).clamp(0.0, 1.0);
        final bump = lv == null ? 0.0 : math.exp(-math.pow(front - pos - 0.5, 2) / 0.35);
        Color color;
        if (lv == null) {
          color = inactive;
        } else {
          final a = Color.lerp(inactive, from, lv)!;
          final b = Color.lerp(inactive, to, lv)!;
          color = Color.lerp(a, b, t)!;
        }
        final s = cell * (1 + 0.14 * bump);
        final cx = ox + c * (cell + gap) + cell / 2;
        final cy = oy + r * (cell + gap) + cell / 2;
        paint.color = color;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: s, height: s),
              Radius.circular(s * 0.26)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter o) =>
      o.from != from || o.to != to || o.front != front || o.inactive != inactive;
}

class ContributionGrid extends StatelessWidget {
  const ContributionGrid({super.key, required this.color, this.height = 90});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: GridPainter(from: color, to: color)),
      );
}
