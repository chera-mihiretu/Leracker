// Page 5 — Grid aesthetics & custom colour palette.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion.dart';
import '../task_draft.dart';
import '../widgets/contribution_grid.dart';
import '../widgets/entrance.dart';

class ColorPage extends StatefulWidget {
  const ColorPage({super.key, required this.draft});
  final TaskDraft draft;

  @override
  State<ColorPage> createState() => _ColorPageState();
}

class _ColorPageState extends State<ColorPage>
    with SingleTickerProviderStateMixin {
  // Wavefront sweeps left → right across the 7 columns in 250ms; the extra
  // time lets the bump on the last column settle.
  late final AnimationController _wave =
      AnimationController(vsync: this, duration: Motion.ms(380), value: 1);
  late Color _from = widget.draft.color;

  void _pick(Color c) {
    if (c == widget.draft.color) return;
    HapticFeedback.selectionClick();
    setState(() => _from = _currentBlend());
    widget.draft.update(() => widget.draft.color = c);
    _wave.forward(from: 0);
  }

  // If a wave is mid-flight, start the next one from the old colour.
  Color _currentBlend() => _wave.isAnimating ? _from : widget.draft.color;

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return AnimatedBuilder(
      animation: draft,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          const PageHeader(title: 'Choose the color for your contribution grid'),
          const SizedBox(height: 28),
          Entrance(
            delay: Motion.ms(80),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: PT.slate,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                height: 150,
                child: AnimatedBuilder(
                  animation: _wave,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: GridPainter(
                      from: _from,
                      to: draft.color,
                      // 250ms of the 380ms run covers all 7 columns + skew.
                      front: _wave.value / (250 / 380) * 8.6 - 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Entrance(
            delay: Motion.ms(150),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final s in PT.swatches)
                  _Swatch(
                    color: s.$2,
                    selected: draft.color == s.$2,
                    onTap: () => _pick(s.$2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: AnimatedSwitcher(
              duration: Motion.ms(200),
              child: Text(
                PT.swatches.firstWhere((s) => s.$2 == draft.color).$1,
                key: ValueKey(draft.color),
                style: const TextStyle(fontSize: 14, color: PT.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatefulWidget {
  const _Swatch(
      {required this.color, required this.selected, required this.onTap});
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_Swatch> createState() => _SwatchState();
}

class _SwatchState extends State<_Swatch> with SingleTickerProviderStateMixin {
  late final AnimationController _pop =
      AnimationController(vsync: this, duration: Motion.ms(320), value: 1);

  @override
  void didUpdateWidget(covariant _Swatch old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.color.computeLuminance() > 0.5;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pop,
        builder: (context, child) => Transform.scale(
          // Pop: 1.2 → 1.0 when selected.
          scale: widget.selected
              ? 1 + 0.2 * (1 - Motion.decel.transform(_pop.value))
              : 1,
          child: child,
        ),
        child: AnimatedContainer(
          duration: Motion.ms(200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            border: Border.all(
              color: widget.selected ? PT.text : Colors.transparent,
              width: 2.5,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: AnimatedScale(
            scale: widget.selected ? 1 : 0,
            duration: Motion.ms(260),
            curve: Motion.spring,
            child: Icon(Icons.check_rounded,
                size: 22, color: dark ? PT.obsidian : Colors.white),
          ),
        ),
      ),
    );
  }
}
