// Progress Tracker — animated logo mark.
//
// A 5×5 grid of rounded tiles that tells the "effort → streak" story:
//   0.00–0.40s  Slate grid    : grey tiles spring into place
//   0.40–1.40s  Chain reaction: tiles light up column by column (like a
//                               GitHub contribution graph) with a tactile
//                               mechanical-switch pop
//   1.40–1.80s  Completion    : the last tile clicks, a light ripple travels
//                               across the grid and locks a bold checkmark
//   1.80–2.50s  Rest          : the checkmark breathes with a soft glow
//
// Pure Flutter (CustomPainter + Ticker). No packages, no assets.
//
// Usage:
//   const ProgressTrackerLogo(size: 160)                       // intro, then breathes forever
//   ProgressTrackerLogo(onCompleted: () => goHome())           // splash screen
//   const ProgressTrackerLogo(mode: ProgressLogoMode.loop)     // loading indicator
//   const ProgressTrackerLogo(mode: ProgressLogoMode.still)    // static mark (app bar, etc.)
//   const ProgressTrackerLogo(showBackground: true)            // app-icon style tile

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Total length of one animation cycle, in seconds.
const double kProgressLogoDuration = 2.5;

enum ProgressLogoMode {
  /// Plays the 2.5s intro once, fires [ProgressTrackerLogo.onCompleted],
  /// then keeps breathing gently. Ideal for splash screens.
  intro,

  /// Seamlessly repeats the full 2.5s story. Ideal for loading states.
  loop,

  /// Renders the final, settled mark without animating.
  still,
}

/// Brand colours. Use [dark] on obsidian backgrounds, [light] on white.
@immutable
class ProgressTrackerPalette {
  const ProgressTrackerPalette({
    required this.emerald,
    required this.jade,
    required this.mint,
    required this.inactive,
    required this.background,
  });

  final Color emerald; // Active / success   #22C55E
  final Color jade; //    Secondary green    #10B981
  final Color mint; //    Highlight / flash  #86EFAC
  final Color inactive; // Pending tile
  final Color background; // Icon tile / splash background

  static const ProgressTrackerPalette dark = ProgressTrackerPalette(
    emerald: Color(0xFF22C55E),
    jade: Color(0xFF10B981),
    mint: Color(0xFF86EFAC),
    inactive: Color(0xFF334155),
    background: Color(0xFF0F172A),
  );

  static const ProgressTrackerPalette light = ProgressTrackerPalette(
    emerald: Color(0xFF22C55E),
    jade: Color(0xFF10B981),
    mint: Color(0xFF86EFAC),
    inactive: Color(0xFFE2E8F0),
    background: Color(0xFFFFFFFF),
  );
}

class ProgressTrackerLogo extends StatefulWidget {
  const ProgressTrackerLogo({
    super.key,
    this.size = 160,
    this.mode = ProgressLogoMode.intro,
    this.palette = ProgressTrackerPalette.dark,
    this.showBackground = false,
    this.speed = 1.0,
    this.autoPlay = true,
    this.onCompleted,
    this.semanticLabel = 'Progress Tracker logo',
  });

  /// Width and height of the logo.
  final double size;
  final ProgressLogoMode mode;
  final ProgressTrackerPalette palette;

  /// Draws the logo on a rounded-square tile (app-icon look).
  final bool showBackground;

  /// Playback speed multiplier (1.0 = 2.5s per cycle).
  final double speed;

  /// Start animating immediately. If false, call `replay()` via a GlobalKey.
  final bool autoPlay;

  /// Called once, when the first 2.5s cycle finishes (or immediately when
  /// the OS "reduce motion" setting is on). Use it to leave a splash screen.
  final VoidCallback? onCompleted;

  final String semanticLabel;

  @override
  State<ProgressTrackerLogo> createState() => ProgressTrackerLogoState();
}

class ProgressTrackerLogoState extends State<ProgressTrackerLogo>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  bool _completedFired = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (widget.mode == ProgressLogoMode.still) {
      _time.value = _settledTime;
    } else if (widget.autoPlay) {
      _ticker.start();
    }
  }

  static const double _settledTime = 2.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce && !_reduceMotion) {
      _reduceMotion = true;
      _ticker.stop();
      _time.value = _settledTime;
      _fireCompletedOnce(postFrame: true);
    }
  }

  @override
  void didUpdateWidget(covariant ProgressTrackerLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      if (widget.mode == ProgressLogoMode.still) {
        _ticker.stop();
        _time.value = _settledTime;
      } else {
        replay();
      }
    }
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6 * widget.speed;
    _time.value = t;
    if (t >= kProgressLogoDuration) _fireCompletedOnce();
  }

  void _fireCompletedOnce({bool postFrame = false}) {
    if (_completedFired) return;
    _completedFired = true;
    final cb = widget.onCompleted;
    if (cb == null) return;
    if (postFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) cb();
      });
    } else {
      cb();
    }
  }

  /// Restart the animation from the empty grey grid.
  void replay() {
    if (_reduceMotion || widget.mode == ProgressLogoMode.still) return;
    _ticker.stop();
    _completedFired = false;
    _time.value = 0;
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _ProgressLogoPainter(
              time: _time,
              loop: widget.mode == ProgressLogoMode.loop && !_reduceMotion,
              palette: widget.palette,
              showBackground: widget.showBackground,
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Grid model
// ───────────────────────────────────────────────────────────────────────────

const int _n = 5;

/// Tiles that form the checkmark: short leg down, long leg up to the corner.
const Set<int> _checkCells = {
  2 * _n + 0, // (row 2, col 0)
  3 * _n + 1, // (row 3, col 1)  ← vertex
  2 * _n + 2, // (row 2, col 2)
  1 * _n + 3, // (row 1, col 3)
  0 * _n + 4, // (row 0, col 4)  ← final tile / ripple origin
};

class _Tile {
  _Tile({
    required this.row,
    required this.col,
    required this.isCheck,
    required this.level,
    required this.appearAt,
    required this.litAt,
    required this.distToTip,
  });

  final int row;
  final int col;
  final bool isCheck;
  final double level; // "contribution level" for background tiles (0..1)
  final double appearAt; // seconds
  final double litAt; // seconds
  final double distToTip; // in tile units
}

final List<_Tile> _tiles = _buildTiles();
final double _maxDist =
    _tiles.map((t) => t.distToTip).reduce(math.max); // ≈ 5.66

List<_Tile> _buildTiles() {
  const levels = [0.22, 0.38, 0.55, 0.30, 0.68];
  const center = (_n - 1) / 2;
  final maxCenterDist = math.sqrt(2) * center;

  final cells = <({int r, int c, bool check})>[
    for (var r = 0; r < _n; r++)
      for (var c = 0; c < _n; c++)
        (r: r, c: c, check: _checkCells.contains(r * _n + c)),
  ];

  // Light-up order: column by column (left → right, like weeks on a
  // contribution graph); inside a column the background tiles go first and the
  // checkmark tile last, so the check is "drawn" stroke by stroke and the very
  // last tile to click is the top-right tip.
  final order = [...cells]..sort((a, b) {
      if (a.c != b.c) return a.c.compareTo(b.c);
      if (a.check != b.check) return a.check ? 1 : -1;
      return a.r.compareTo(b.r);
    });

  const chainStart = 0.40, chainSpan = 0.95;
  final tiles = <_Tile>[];
  for (var i = 0; i < order.length; i++) {
    final cell = order[i];
    final dc = math.sqrt(math.pow(cell.r - center, 2) + math.pow(cell.c - center, 2));
    tiles.add(_Tile(
      row: cell.r,
      col: cell.c,
      isCheck: cell.check,
      level: levels[(cell.r * 7 + cell.c * 3) % levels.length],
      appearAt: 0.15 * (dc / maxCenterDist),
      litAt: chainStart + chainSpan * i / (order.length - 1),
      distToTip: math.sqrt(math.pow(cell.r - 0, 2) + math.pow(cell.c - 4, 2)),
    ));
  }
  return tiles;
}

// ───────────────────────────────────────────────────────────────────────────
// Easing helpers
// ───────────────────────────────────────────────────────────────────────────

double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

double _smoothstep(double e0, double e1, double x) {
  final t = _clamp01((x - e0) / (e1 - e0));
  return t * t * (3 - 2 * t);
}

double _easeOutBack(double t) {
  const c1 = 1.70158, c3 = c1 + 1;
  return (1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)).toDouble();
}

double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();

/// Damped spring: snaps up (~+12%), dips once, settles in ~0.4s.
/// Feels like a mechanical key rather than a floaty bounce.
double _springPop(double x) {
  if (x <= 0 || x > 0.6) return 0;
  return 0.22 * math.exp(-9 * x) * math.sin(22 * x);
}

Color _lerp(Color a, Color b, double t) => Color.lerp(a, b, _clamp01(t))!;

Color _alpha(Color c, double opacity) =>
    c.withAlpha((_clamp01(opacity) * 255).round());

// ───────────────────────────────────────────────────────────────────────────
// Painter
// ───────────────────────────────────────────────────────────────────────────

class _TileState {
  _TileState(this.rect, this.color, this.glow);
  final RRect rect;
  final Color color;
  final double glow;
}

class _ProgressLogoPainter extends CustomPainter {
  _ProgressLogoPainter({
    required this.time,
    required this.loop,
    required this.palette,
    required this.showBackground,
  }) : super(repaint: time);

  final ValueListenable<double> time;
  final bool loop;
  final ProgressTrackerPalette palette;
  final bool showBackground;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Timeline ──────────────────────────────────────────────────────────
    final raw = time.value;
    double t = raw;
    var firstCycle = true;
    if (loop) {
      final cycle = (raw / kProgressLogoDuration).floor();
      t = raw - cycle * kProgressLogoDuration;
      firstCycle = cycle == 0;
    }

    // ── Layout ────────────────────────────────────────────────────────────
    final side = size.shortestSide;
    final origin = Offset((size.width - side) / 2, (size.height - side) / 2);
    final pad = side * (showBackground ? 0.19 : 0.10);
    final gridSide = side - pad * 2;
    final gap = gridSide * 0.05;
    final tile = (gridSide - gap * (_n - 1)) / _n;
    final radius = Radius.circular(tile * 0.26);

    Offset centerOf(int r, int c) =>
        origin +
        Offset(pad + c * (tile + gap) + tile / 2, pad + r * (tile + gap) + tile / 2);

    if (showBackground) {
      final bg = RRect.fromRectAndRadius(origin & Size.square(side),
          Radius.circular(side * 0.225));
      canvas.drawRRect(bg, Paint()..color = palette.background);
      canvas.save();
      canvas.clipRRect(bg);
    }

    // ── Global phase values ───────────────────────────────────────────────
    const rippleStart = 1.40, rippleDur = 0.40;
    final rippleR = (t - rippleStart) / rippleDur * (_maxDist + 1.5);
    final breatheIn = _smoothstep(1.70, 1.95, t);
    final breathe = t > 1.8 ? math.sin(2 * math.pi * (t - 1.8) / 2.0) : 0.0;
    final loopFade = loop ? _smoothstep(2.20, 2.50, t) : 0.0;

    // ── Completion bloom (soft radial flash from the last tile) ──────────
    if (t > 1.33 && t < 2.0) {
      final p = _clamp01((t - 1.35) / 0.55);
      final double a =
          0.45 * (1 - p) * (1 - p) * _clamp01((t - 1.33) / 0.06);
      final bloomR = tile * (1.0 + 7.0 * _easeOutCubic(p));
      final c = centerOf(0, 4);
      canvas.drawCircle(
        c,
        bloomR,
        Paint()
          ..shader = ui.Gradient.radial(c, bloomR, [
            _alpha(palette.mint, a),
            _alpha(palette.emerald, a * 0.35),
            _alpha(palette.emerald, 0),
          ], const [0.0, 0.45, 1.0]),
      );
    }

    // ── Per-tile state ────────────────────────────────────────────────────
    final states = <_TileState>[];
    for (final tl in _tiles) {
      final appear = firstCycle
          ? _easeOutBack(_clamp01((t - tl.appearAt) / 0.25))
          : 1.0;
      if (appear <= 0.001) continue;

      final lt = t - tl.litAt;
      final lit = lt <= 0 ? 0.0 : _easeOutCubic(_clamp01(lt / 0.10));
      final flash = lt <= 0 ? 0.0 : math.exp(-lt * 14);

      final dRipple = tl.distToTip - rippleR;
      final boost = t > rippleStart
          ? math.exp(-(dRipple * dRipple) / (2 * 0.7 * 0.7))
          : 0.0;
      final lock = t > rippleStart
          ? _smoothstep(0, 1, (rippleR - tl.distToTip) / 1.5)
          : 0.0;

      // Colour
      final litColor = tl.isCheck
          ? palette.emerald
          : _lerp(palette.inactive, palette.jade, tl.level);
      var color = _lerp(palette.inactive, litColor, lit);
      color = _lerp(color, palette.mint, flash * 0.65);
      color = _lerp(color, tl.isCheck ? palette.mint : palette.jade,
          boost * (tl.isCheck ? 0.7 : 0.35));
      if (!tl.isCheck) {
        // Background tiles recede so the checkmark reads boldly.
        final rest = _lerp(palette.inactive, palette.jade, tl.level * 0.40);
        color = _lerp(color, rest, lock);
      }
      color = _lerp(color, palette.inactive, loopFade);

      // Scale
      var scale = appear * (1 + _springPop(lt) + 0.08 * boost);
      if (tl.isCheck) scale *= 1 + 0.018 * breathe * breatheIn;

      // Glow (checkmark only)
      final glow = tl.isCheck
          ? lit *
              (0.30 * flash +
                  0.70 * boost +
                  lock * (0.50 + 0.22 * breathe * breatheIn)) *
              (1 - loopFade)
          : 0.0;

      final s = tile * scale;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: centerOf(tl.row, tl.col), width: s, height: s),
        radius * scale,
      );
      states.add(_TileState(rect, color, glow));
    }

    // Pass 1: glows underneath everything.
    final glowPaint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, tile * 0.32);
    for (final st in states) {
      if (st.glow <= 0.01) continue;
      glowPaint.color = _alpha(palette.emerald, 0.75 * st.glow);
      canvas.drawRRect(st.rect.inflate(tile * 0.06), glowPaint);
    }

    // Pass 2: the tiles.
    final tilePaint = Paint()..isAntiAlias = true;
    for (final st in states) {
      tilePaint.color = st.color;
      canvas.drawRRect(st.rect, tilePaint);
    }

    if (showBackground) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ProgressLogoPainter old) =>
      old.time != time ||
      old.loop != loop ||
      old.palette != palette ||
      old.showBackground != showBackground;
}

// ───────────────────────────────────────────────────────────────────────────
// Ready-made splash screen
// ───────────────────────────────────────────────────────────────────────────

/// Full-screen splash: plays the logo intro, fades in the wordmark, then calls
/// [onFinished] (e.g. to push your home route).
class ProgressTrackerSplash extends StatefulWidget {
  const ProgressTrackerSplash({
    super.key,
    this.onFinished,
    this.palette = ProgressTrackerPalette.dark,
    this.logoSize = 132,
    this.title = 'Progress Tracker',
    this.tagline = 'Build your wall of green.',
    this.holdAfter = const Duration(milliseconds: 350),
  });

  final VoidCallback? onFinished;
  final ProgressTrackerPalette palette;
  final double logoSize;
  final String title;
  final String? tagline;
  final Duration holdAfter;

  @override
  State<ProgressTrackerSplash> createState() => _ProgressTrackerSplashState();
}

class _ProgressTrackerSplashState extends State<ProgressTrackerSplash> {
  bool _showText = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) setState(() => _showText = true);
    });
  }

  void _onLogoDone() {
    Future.delayed(widget.holdAfter, () {
      if (mounted) widget.onFinished?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.palette.background.computeLuminance() < 0.5;
    final titleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return ColoredBox(
      color: widget.palette.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProgressTrackerLogo(
              size: widget.logoSize,
              palette: widget.palette,
              onCompleted: _onLogoDone,
            ),
            const SizedBox(height: 28),
            AnimatedOpacity(
              opacity: _showText ? 1 : 0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: _showText ? Offset.zero : const Offset(0, 0.25),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                child: Column(
                  children: [
                    Text(
                      widget.title,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                        color: titleColor,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (widget.tagline != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.tagline!,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                          color: subColor,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
