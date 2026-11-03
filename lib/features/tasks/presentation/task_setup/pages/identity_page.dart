// Page 1 — Task identity & purpose.
import 'dart:async';

import 'package:flutter/material.dart';

import '../motion.dart';
import '../task_draft.dart';
import '../widgets/entrance.dart';

class IdentityPage extends StatefulWidget {
  const IdentityPage({super.key, required this.draft});
  final TaskDraft draft;

  @override
  State<IdentityPage> createState() => _IdentityPageState();
}

class _IdentityPageState extends State<IdentityPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _text =
      TextEditingController(text: widget.draft.name);
  final FocusNode _focus = FocusNode();
  late final AnimationController _underline =
      AnimationController(vsync: this, duration: Motion.ms(320));
  Timer? _typer;

  static const _presets = <(String, IconData)>[
    ('Read', Icons.menu_book_rounded),
    ('Workout', Icons.fitness_center_rounded),
    ('Meditate', Icons.self_improvement_rounded),
    ('Code', Icons.code_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      _focus.hasFocus ? _underline.forward() : _underline.reverse();
    });
    _text.addListener(() => widget.draft.update(() => widget.draft.name = _text.text));
  }

  @override
  void dispose() {
    _typer?.cancel();
    _text.dispose();
    _focus.dispose();
    _underline.dispose();
    super.dispose();
  }

  /// Rapid typing effect: clears the field and types [word] letter by letter.
  void _typeIn(String word) {
    _typer?.cancel();
    var i = 0;
    _text.text = '';
    _typer = Timer.periodic(Motion.ms(38), (t) {
      i++;
      _text.value = TextEditingValue(
        text: word.substring(0, i),
        selection: TextSelection.collapsed(offset: i),
      );
      if (i >= word.length) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        const PageHeader(title: 'What habit or goal are you committing to?'),
        const SizedBox(height: 36),

        // Input field: 100–350ms
        Entrance(
          delay: Motion.ms(100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _text,
                focusNode: _focus,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w500, color: PT.text),
                cursorColor: PT.emerald,
                cursorWidth: 2.5,
                cursorRadius: const Radius.circular(2),
                cursorOpacityAnimates: true, // soft breathing blink
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Read 20 pages',
                  hintStyle: TextStyle(color: PT.textFaint, fontSize: 24),
                ),
              ),
              const SizedBox(height: 12),
              _CenterUnderline(animation: _underline),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Preset chips: 200–500ms, 50ms stagger, 0.8 → 1.05 → 1.0
        AnimatedBuilder(
          animation: widget.draft,
          builder: (context, _) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _presets.length; i++)
                Entrance(
                  delay: Motion.ms(200 + 50 * i),
                  duration: Motion.ms(300),
                  offsetY: 0,
                  fromScale: 0.8,
                  curve: Motion.spring,
                  child: _PresetChip(
                    label: _presets[i].$1,
                    icon: _presets[i].$2,
                    selected: widget.draft.name == _presets[i].$1,
                    onTap: () => _typeIn(_presets[i].$1),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom line that expands from the centre outward on focus, glowing emerald.
class _CenterUnderline extends StatelessWidget {
  const _CenterUnderline({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: Stack(
        children: [
          const Positioned(
              left: 0, right: 0, bottom: 0, height: 1,
              child: ColoredBox(color: PT.inactive)),
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = Motion.decel.transform(animation.value);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(t, 1, 1),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: PT.emerald,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: fade(PT.emerald, 0.6 * t), blurRadius: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squash(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.ms(200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? fade(PT.emerald, 0.15) : PT.slate,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? PT.emerald : PT.inactive),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? PT.emerald : PT.textMuted),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: selected ? PT.text : PT.textMuted)),
          ],
        ),
      ),
    );
  }
}
