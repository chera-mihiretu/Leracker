// Morning Review: a fast binary sweep (Done / Missed) through yesterday's
// unreviewed tasks. Tap the buttons or swipe the card right (done) / left.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../task_setup/motion.dart';
import '../dash_theme.dart';
import '../dashboard_store.dart';
import '../task_item.dart';

Future<void> openMorningReview(BuildContext context, DashboardStore store) {
  final palette = DashTheme.of(context);
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: Motion.ms(380),
    reverseTransitionDuration: Motion.ms(280),
    pageBuilder: (_, _, _) =>
        DashTheme(palette: palette, child: MorningReview(store: store)),
    transitionsBuilder: (_, a, _, child) {
      final c = CurvedAnimation(parent: a, curve: Motion.decel);
      return FadeTransition(
        opacity: c,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(c),
          child: child,
        ),
      );
    },
  ));
}

class MorningReview extends StatefulWidget {
  const MorningReview({super.key, required this.store});
  final DashboardStore store;

  @override
  State<MorningReview> createState() => _MorningReviewState();
}

class _MorningReviewState extends State<MorningReview>
    with SingleTickerProviderStateMixin {
  late final List<TaskItem> _items = widget.store.toReview;
  int _index = 0;
  double _dragX = 0;
  int _lastDir = 1; // 1 = flew right (done), -1 = left (missed)
  late final AnimationController _settle =
      AnimationController(vsync: this, duration: Motion.ms(260));
  double _settleFrom = 0;

  @override
  void initState() {
    super.initState();
    _settle.addListener(() => setState(() =>
        _dragX = _settleFrom * (1 - Motion.spring.transform(_settle.value))));
  }

  bool get _finished => _index >= _items.length;

  void _answer(EntryStatus s) {
    if (_finished) return;
    s == EntryStatus.done
        ? HapticFeedback.mediumImpact()
        : HapticFeedback.lightImpact();
    widget.store.setStatus(_items[_index], widget.store.yesterday, s);
    setState(() {
      _lastDir = s == EntryStatus.done ? 1 : -1;
      _settle.stop();
      _dragX = 0;
      _index++;
    });
    if (_finished) {
      Timer(const Duration(milliseconds: 1300), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dx;
    if (_dragX > 110 || v > 800) return _answer(EntryStatus.done);
    if (_dragX < -110 || v < -800) return _answer(EntryStatus.missed);
    // Spring back to centre.
    _settleFrom = _dragX;
    _settle.forward(from: 0);
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_twilight_rounded, color: DashPalette.amber),
                  const SizedBox(width: 8),
                  Text('Morning review',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: p.text)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close_rounded, color: p.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Progress dots
              Row(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: Motion.ms(280),
                        curve: Motion.decel,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i < _index ? DashPalette.amber : p.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Yesterday · ${shortDate(widget.store.yesterday)}',
                  style: TextStyle(fontSize: 13, color: p.textMuted)),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: Motion.ms(320),
                    switchInCurve: Motion.decel,
                    transitionBuilder: (child, a) {
                      final incoming = child.key == ValueKey(_index);
                      if (incoming) {
                        return FadeTransition(
                          opacity: a,
                          child: ScaleTransition(
                              scale: Tween(begin: 0.92, end: 1.0).animate(a),
                              child: child),
                        );
                      }
                      return AnimatedBuilder(
                        animation: a,
                        child: child,
                        builder: (context, c) => Opacity(
                          opacity: a.value,
                          child: Transform.translate(
                            offset: Offset(_lastDir * 220 * (1 - a.value), 0),
                            child: Transform.rotate(
                                angle: _lastDir * 0.25 * (1 - a.value), child: c),
                          ),
                        ),
                      );
                    },
                    child: _finished
                        ? KeyedSubtree(
                            key: ValueKey(_index), child: _CaughtUp(palette: p))
                        : KeyedSubtree(
                            key: ValueKey(_index),
                            child: GestureDetector(
                              onHorizontalDragUpdate: (d) =>
                                  setState(() => _dragX += d.delta.dx),
                              onHorizontalDragEnd: _onDragEnd,
                              child: Transform.translate(
                                offset: Offset(_dragX, 0),
                                child: Transform.rotate(
                                  angle: _dragX / 1400,
                                  child: _ReviewCard(
                                    task: _items[_index],
                                    drag: _dragX,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: _finished ? 0 : 1,
                duration: Motion.ms(200),
                child: Row(
                  children: [
                    Expanded(
                      child: _BigButton(
                        label: 'Missed',
                        icon: Icons.close_rounded,
                        color: p.missed,
                        fg: p.text,
                        onTap: () => _answer(EntryStatus.missed),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BigButton(
                        label: 'Done',
                        icon: Icons.check_rounded,
                        color: DashPalette.emerald,
                        fg: Colors.white,
                        onTap: () => _answer(EntryStatus.done),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.task, required this.drag});
  final TaskItem task;
  final double drag;

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    final lean = (drag / 140).clamp(-1.0, 1.0);
    final tint = lean > 0
        ? DashPalette.emerald.withAlpha((lean * 90).round())
        : p.missed.withAlpha((-lean * 160).round());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Color.alphaBlend(tint, p.card),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: lean > 0.3 ? DashPalette.emerald : p.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: task.gridColor.withAlpha(40),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.grid_view_rounded, color: task.gridColor),
          ),
          const SizedBox(height: 20),
          Text(task.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: p.text)),
          const SizedBox(height: 6),
          Text('Did you do it?',
              style: TextStyle(fontSize: 15, color: p.textMuted)),
          const SizedBox(height: 16),
          Text('Swipe right for done, left for missed',
              style: TextStyle(fontSize: 12, color: p.textFaint)),
        ],
      ),
    );
  }
}

class _CaughtUp extends StatelessWidget {
  const _CaughtUp({required this.palette});
  final DashPalette palette;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Motion.ms(500),
            curve: Motion.spring,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DashPalette.emerald,
                boxShadow: [
                  BoxShadow(
                      color: DashPalette.emerald.withAlpha(110), blurRadius: 24),
                ],
              ),
              child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          Text('All caught up',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: palette.text)),
        ],
      );
}

class _BigButton extends StatefulWidget {
  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.fg,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color, fg;
  final VoidCallback onTap;

  @override
  State<_BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<_BigButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: Motion.ms(_down ? 90 : 240),
          curve: _down ? Curves.easeOut : Motion.spring,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: widget.fg),
                const SizedBox(width: 8),
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: widget.fg)),
              ],
            ),
          ),
        ),
      );
}
