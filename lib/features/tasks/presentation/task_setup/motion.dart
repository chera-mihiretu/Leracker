// Shared motion DNA + palette for the Task Setup flow.
import 'package:flutter/animation.dart';

abstract final class Motion {
  /// cubic-bezier(0.34, 1.56, 0.64, 1): snappy overshoot, zero wobble.
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1);

  /// cubic-bezier(0.16, 1, 0.3, 1): smooth deceleration for big slides.
  static const Curve decel = Cubic(0.16, 1, 0.3, 1);

  static const Duration page = Duration(milliseconds: 320);
  static const Duration progress = Duration(milliseconds: 280);
  static const Duration stagger = Duration(milliseconds: 50);

  static Duration ms(int v) => Duration(milliseconds: v);
}

abstract final class PT {
  static const emerald = Color(0xFF22C55E);
  static const jade = Color(0xFF10B981);
  static const mint = Color(0xFF86EFAC);
  static const obsidian = Color(0xFF0F172A);
  static const slate = Color(0xFF1E293B);
  static const inactive = Color(0xFF334155);
  static const inactiveLight = Color(0xFFE2E8F0);
  static const text = Color(0xFFF8FAFC);
  static const textMuted = Color(0xFF94A3B8);
  static const textFaint = Color(0xFF64748B);

  static const swatches = <(String, Color)>[
    ('Emerald', Color(0xFF22C55E)),
    ('Mint', Color(0xFF86EFAC)),
    ('Jade', Color(0xFF10B981)),
    ('Violet', Color(0xFF8B5CF6)),
    ('Amber', Color(0xFFF59E0B)),
    ('Cyan', Color(0xFF06B6D4)),
  ];
}

Color fade(Color c, double opacity) =>
    c.withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
