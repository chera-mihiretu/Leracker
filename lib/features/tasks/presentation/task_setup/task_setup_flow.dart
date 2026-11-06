// Task Setup flow: progress bar, 6 pages, depth-layered page transitions.
import 'package:flutter/material.dart';

import 'motion.dart';
import 'pages/color_page.dart';
import 'pages/frequency_page.dart';
import 'pages/identity_page.dart';
import 'pages/nudge_page.dart';
import 'pages/review_page.dart';
import 'pages/time_page.dart';
import 'task_draft.dart';
import 'task_list_screen.dart';
import 'widgets/entrance.dart';
import 'widgets/segmented_progress.dart';

class TaskSetupFlow extends StatefulWidget {
  const TaskSetupFlow({super.key, this.onCreated});

  /// Optional override. By default the flow fades into [TaskListScreen] and
  /// the review card morphs (Hero) into the first card of the list.
  final void Function(TaskDraft draft)? onCreated;

  @override
  State<TaskSetupFlow> createState() => _TaskSetupFlowState();
}

class _TaskSetupFlowState extends State<TaskSetupFlow> {
  static const _pageCount = 6;
  final TaskDraft _draft = TaskDraft();
  int _step = 0;
  bool _forward = true;

  void _go(int delta) {
    final next = (_step + delta).clamp(0, _pageCount - 1);
    if (next == _step) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = delta > 0;
      _step = next;
    });
  }

  bool get _canContinue => _step != 0 || _draft.name.trim().isNotEmpty;

  void _finish() {
    if (widget.onCreated != null) {
      widget.onCreated!(_draft);
      return;
    }
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: Motion.ms(600),
      pageBuilder: (_, _, _) => TaskListScreen(newTask: _draft),
      transitionsBuilder: (_, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Motion.decel),
        child: child,
      ),
    ));
  }

  Widget _page(int i) => switch (i) {
        0 => IdentityPage(draft: _draft),
        1 => FrequencyPage(draft: _draft),
        2 => TimePage(draft: _draft),
        3 => NudgePage(draft: _draft),
        4 => ColorPage(draft: _draft),
        _ => ReviewPage(draft: _draft, onCreate: _finish),
      };

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(-1);
      },
      child: Scaffold(
        backgroundColor: PT.obsidian,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    AnimatedOpacity(
                      opacity: _step == 0 ? 0 : 1,
                      duration: Motion.ms(200),
                      child: IconButton(
                        onPressed: _step == 0 ? null : () => _go(-1),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: PT.textMuted),
                      ),
                    ),
                    Expanded(child: SegmentedProgress(step: _step)),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.page,
                  reverseDuration: Motion.page,
                  switchInCurve: Motion.decel,
                  switchOutCurve: Curves.easeOut,
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [...previous, ?current],
                  ),
                  transitionBuilder: (child, anim) {
                    final incoming = child.key == ValueKey(_step);
                    if (incoming) {
                      // Slides in from the right (or left going back): ±24dp.
                      final dx = _forward ? 24.0 : -24.0;
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
                    }
                    // Outgoing: fades and scales down to 0.96 (depth layer).
                    return AnimatedBuilder(
                      animation: anim,
                      child: child,
                      builder: (context, c) => Opacity(
                        opacity: anim.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.96 + 0.04 * anim.value,
                          child: c,
                        ),
                      ),
                    );
                  },
                  child: KeyedSubtree(key: ValueKey(_step), child: _page(_step)),
                ),
              ),
              if (_step < _pageCount - 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: AnimatedBuilder(
                    animation: _draft,
                    builder: (context, _) => _ContinueButton(
                      enabled: _canContinue,
                      onTap: () => _go(1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squash(
      pressedScale: 0.97,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: Motion.ms(200),
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? PT.text : PT.slate,
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedDefaultTextStyle(
          duration: Motion.ms(200),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: enabled ? PT.obsidian : PT.textFaint,
          ),
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
