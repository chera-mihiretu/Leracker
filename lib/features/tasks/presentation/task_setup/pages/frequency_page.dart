// Page 2 — Repetition & frequency cadence.
//
// Daily   → Every day / Weekdays / Weekends / Custom + day pills
// Weekly  → once a week: pick one day of the week
// Monthly → once a month: Start of month, End of month, or a day number
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion.dart';
import '../task_draft.dart';
import '../widgets/entrance.dart';

class FrequencyPage extends StatefulWidget {
  const FrequencyPage({super.key, required this.draft});
  final TaskDraft draft;

  @override
  State<FrequencyPage> createState() => _FrequencyPageState();
}

class _FrequencyPageState extends State<FrequencyPage> {
  int _dir = 1; // slide direction when switching Daily/Weekly/Monthly

  void _pickFrequency(Frequency f) {
    final cur = widget.draft.frequency;
    if (f == cur) return;
    HapticFeedback.selectionClick();
    setState(() => _dir = f.index > cur.index ? 1 : -1);
    widget.draft.update(() => widget.draft.frequency = f);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return AnimatedBuilder(
      animation: draft,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          const PageHeader(title: 'How often do you want to perform this?'),
          const SizedBox(height: 24),
          Entrance(
            delay: Motion.ms(60),
            child: _FrequencySwitch(
              value: draft.frequency,
              onChanged: _pickFrequency,
            ),
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: Motion.page,
            switchInCurve: Motion.decel,
            switchOutCurve: Curves.easeOut,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            transitionBuilder: (child, anim) {
              final incoming = child.key == ValueKey(draft.frequency);
              final dx = (incoming ? 24.0 : -24.0) * _dir;
              return AnimatedBuilder(
                animation: anim,
                child: child,
                builder: (context, c) => Opacity(
                  opacity: anim.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(dx * (1 - anim.value), 0),
                    child: c,
                  ),
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(draft.frequency),
              child: switch (draft.frequency) {
                Frequency.daily => _DailyOptions(draft: draft),
                Frequency.weekly => _WeeklyPicker(draft: draft),
                Frequency.monthly => _MonthlyPicker(draft: draft),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Daily / Weekly / Monthly switch with a sliding spring pill ───────────

class _FrequencySwitch extends StatelessWidget {
  const _FrequencySwitch({required this.value, required this.onChanged});
  final Frequency value;
  final ValueChanged<Frequency> onChanged;

  static const _labels = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final segW = box.maxWidth / 3;
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: PT.slate,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Motion.ms(300),
              curve: Motion.spring,
              left: value.index * segW + 4,
              top: 4,
              bottom: 4,
              width: segW - 8,
              child: Container(
                decoration: BoxDecoration(
                  color: PT.emerald,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: fade(PT.emerald, 0.4), blurRadius: 14),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(Frequency.values[i]),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.ms(200),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: value.index == i ? Colors.white : PT.textMuted,
                          ),
                          child: Text(_labels[i]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ── Daily: the original structure ────────────────────────────────────────

class _DailyOptions extends StatefulWidget {
  const _DailyOptions({required this.draft});
  final TaskDraft draft;

  @override
  State<_DailyOptions> createState() => _DailyOptionsState();
}

class _DailyOptionsState extends State<_DailyOptions> {
  bool _cascade = false; // true when a preset (not a pill tap) changed days

  static const _options = <(Cadence, String, String)>[
    (Cadence.everyDay, 'Every day', '7 days a week'),
    (Cadence.weekdays, 'Weekdays', 'Monday to Friday'),
    (Cadence.weekends, 'Weekends', 'Saturday and Sunday'),
    (Cadence.custom, 'Custom', 'Pick your days below'),
  ];

  void _pickCadence(Cadence c) {
    setState(() => _cascade = true);
    widget.draft.update(() {
      widget.draft.cadence = c;
      widget.draft.days = TaskDraft.daysFor(c, widget.draft.days);
    });
  }

  void _toggleDay(int d) {
    final days = {...widget.draft.days};
    days.contains(d) ? days.remove(d) : days.add(d);
    if (days.isEmpty) return;
    setState(() => _cascade = false);
    widget.draft.update(() {
      widget.draft.days = days;
      widget.draft.cadence = Cadence.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Column(
      children: [
        for (var i = 0; i < _options.length; i++)
          Entrance(
            delay: Motion.ms(40 * i), // 40ms cascade from the bottom
            duration: Motion.ms(320),
            offsetY: 28,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionCard(
                title: _options[i].$2,
                subtitle: _options[i].$3,
                selected: draft.cadence == _options[i].$1,
                onTap: () => _pickCadence(_options[i].$1),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Entrance(
          delay: Motion.ms(180),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var d = 0; d < 7; d++)
                _DayPill(
                  label: 'MTWTFSS'[d],
                  selected: draft.days.contains(d),
                  // Weekdays etc.: green dominoes, 45ms apart (180ms M→F).
                  delay: _cascade ? Motion.ms(45 * d) : Duration.zero,
                  onTap: () => _toggleDay(d),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Weekly: once a week, one day ─────────────────────────────────────────

class _WeeklyPicker extends StatelessWidget {
  const _WeeklyPicker({required this.draft});
  final TaskDraft draft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Entrance(
          child: Text('Once a week. Which day?',
              style: TextStyle(fontSize: 15, color: PT.textMuted)),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var d = 0; d < 7; d++)
              Entrance(
                delay: Motion.ms(40 + 45 * d),
                duration: Motion.ms(300),
                offsetY: 0,
                fromScale: 0.8,
                curve: Motion.spring,
                child: _DayPill(
                  label: 'MTWTFSS'[d],
                  selected: draft.weekDay == d,
                  delay: Duration.zero,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    draft.update(() => draft.weekDay = d);
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 26),
        _SummaryLine(text: 'Every ${TaskDraft.weekDayNames[draft.weekDay]}'),
      ],
    );
  }
}

// ── Monthly: once a month, Start / End / day number ──────────────────────

class _MonthlyPicker extends StatelessWidget {
  const _MonthlyPicker({required this.draft});
  final TaskDraft draft;

  void _pick(int day) {
    HapticFeedback.selectionClick();
    draft.update(() => draft.monthDay = day);
  }

  @override
  Widget build(BuildContext context) {
    final md = draft.monthDay;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Entrance(
          child: Text('Once a month. Which day?',
              style: TextStyle(fontSize: 15, color: PT.textMuted)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Entrance(
                delay: Motion.ms(40),
                duration: Motion.ms(320),
                offsetY: 28,
                child: _OptionCard(
                  title: 'Start of month',
                  subtitle: 'The 1st',
                  selected: md == 1,
                  onTap: () => _pick(1),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Entrance(
                delay: Motion.ms(80),
                duration: Motion.ms(320),
                offsetY: 28,
                child: _OptionCard(
                  title: 'End of month',
                  subtitle: 'The last day',
                  selected: md == kEndOfMonth,
                  onTap: () => _pick(kEndOfMonth),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Entrance(
          delay: Motion.ms(120),
          child: const Text('Or pick a day',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PT.textFaint)),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: EdgeInsets.zero,
          children: [
            for (var day = 1; day <= 31; day++)
              Entrance(
                // Calendar ripples in, row by row (capped so it stays snappy).
                delay: Motion.ms(140 + math.min(day * 9, 260)),
                duration: Motion.ms(280),
                offsetY: 0,
                fromScale: 0.8,
                curve: Motion.spring,
                child: Center(
                  child: _DayPill(
                    label: '$day',
                    size: 36,
                    selected: md == day,
                    delay: Duration.zero,
                    onTap: () => _pick(day),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _SummaryLine(text: draft.scheduleLabel),
        AnimatedSize(
          duration: Motion.ms(220),
          curve: Motion.decel,
          child: md >= 29
              ? const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'In shorter months this falls on the last day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: PT.textFaint),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

// ── Shared pieces ─────────────────────────────────────────────────────────

/// "Every Monday" / "Monthly on the 15th", re-animating when it changes.
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: Motion.ms(220),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.3), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Motion.decel)),
            child: child,
          ),
        ),
        child: Text(
          text,
          key: ValueKey(text),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: PT.emerald,
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squash(
      pressedScale: 0.98,
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.ms(200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? fade(PT.emerald, 0.08) : PT.slate,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? PT.emerald : PT.inactive,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: PT.text)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(fontSize: 13, color: PT.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: Motion.ms(220),
              curve: Motion.spring,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? PT.emerald : Colors.transparent,
                border: Border.all(
                    color: selected ? PT.emerald : PT.inactive, width: 2),
              ),
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: Motion.ms(220),
                curve: Motion.spring,
                child: const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular pill (day letter or date). Selecting it pulses to 1.15× and
/// fills emerald.
class _DayPill extends StatefulWidget {
  const _DayPill({
    required this.label,
    required this.selected,
    required this.delay,
    required this.onTap,
    this.size = 40,
  });

  final String label;
  final bool selected;
  final Duration delay;
  final VoidCallback onTap;
  final double size;

  @override
  State<_DayPill> createState() => _DayPillState();
}

class _DayPillState extends State<_DayPill>
    with SingleTickerProviderStateMixin {
  late bool _on = widget.selected;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: Motion.ms(260));
  Timer? _timer;

  @override
  void didUpdateWidget(covariant _DayPill old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) {
      _timer?.cancel();
      void apply() {
        if (!mounted) return;
        setState(() => _on = widget.selected);
        if (_on) _pulse.forward(from: 0);
      }

      widget.delay == Duration.zero ? apply() : _timer = Timer(widget.delay, apply);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.15 * math.sin(math.pi * _pulse.value),
          child: child,
        ),
        child: AnimatedContainer(
          duration: Motion.ms(160),
          curve: Curves.easeOut,
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _on ? PT.emerald : Colors.transparent,
            border:
                Border.all(color: _on ? PT.emerald : PT.inactive, width: 1.5),
            boxShadow: [
              if (_on) BoxShadow(color: fade(PT.emerald, 0.35), blurRadius: 12),
            ],
          ),
          child: AnimatedDefaultTextStyle(
            duration: Motion.ms(160),
            style: TextStyle(
              fontSize: widget.size < 40 ? 13 : 14,
              fontWeight: FontWeight.w600,
              color: _on ? Colors.white : PT.textMuted,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
