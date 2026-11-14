// Main dashboard: header → hero pulse → filter tabs → task cards → FAB.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../task_setup/motion.dart';
import '../task_setup/task_draft.dart';
import '../task_setup/task_setup_flow.dart';
import '../task_setup/widgets/entrance.dart';
import 'dash_theme.dart';
import 'dashboard_store.dart';
import 'task_item.dart';
import 'widgets/filter_tabs.dart';
import 'widgets/header.dart';
import 'widgets/hero_pulse.dart';
import 'widgets/morning_review.dart';
import 'widgets/task_card.dart';
import 'widgets/zero_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    this.userInitials = 'AB',
    this.userAvatarUrl,
    this.onSignOut,
    this.onDraftCreated,
  });

  final DashboardStore store;
  final String userInitials;
  final String? userAvatarUrl;
  final VoidCallback? onSignOut;
  final void Function(TaskDraft draft)? onDraftCreated;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _filter = 0; // 0 = All, 1 = Due today
  int _gen = 0; // bump to replay the card stagger

  DashboardStore get store => widget.store;

  void _setFilter(int i) {
    if (i == _filter) return;
    HapticFeedback.selectionClick();
    setState(() {
      _filter = i;
      _gen++;
    });
  }

  void _createHabit() {
    Navigator.of(context).push(PageRouteBuilder<void>(
      transitionDuration: Motion.ms(420),
      reverseTransitionDuration: Motion.ms(300),
      pageBuilder: (_, _, _) => TaskSetupFlow(
        onCreated: (draft) {
          Navigator.of(context).pop();
          store.add(TaskItem.fromDraft(draft));
          widget.onDraftCreated?.call(draft);
          setState(() {
            _filter = 0;
            _gen++;
          });
        },
      ),
      transitionsBuilder: (_, a, _, child) {
        final c = CurvedAnimation(parent: a, curve: Motion.decel);
        return FadeTransition(
          opacity: c,
          child: SlideTransition(
            position:
                Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(c),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final p = store.isDark ? DashPalette.dark : DashPalette.light;
        final tasks = _filter == 0 ? store.tasks : store.dueToday;
        return DashTheme(
          palette: p,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: p.isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: AnimatedContainer(
              duration: Motion.ms(300),
              color: p.bg,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                floatingActionButton: store.tasks.isEmpty
                    ? null
                    : Entrance(
                        delay: Motion.ms(300),
                        fromScale: 0.6,
                        offsetY: 0,
                        curve: Motion.spring,
                        duration: Motion.ms(360),
                        child: _Fab(onTap: _createHabit),
                      ),
                body: SafeArea(
                  bottom: false,
                  child: Builder(builder: (context) {
                    final header = Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: DashHeader(
                        store: store,
                        userInitials: widget.userInitials,
                        userAvatarUrl: widget.userAvatarUrl,
                        onSignOut: widget.onSignOut,
                        onReview: () => openMorningReview(context, store),
                      ),
                    );
                    if (store.tasks.isEmpty) {
                      return Column(children: [
                        header,
                        Expanded(child: ZeroState(onCreate: _createHabit)),
                      ]);
                    }
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        header,
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Entrance(child: HeroPulse(store: store)),
                        ),
                        const SizedBox(height: 26),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'HABITS',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.4,
                                color: p.textFaint),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FilterTabs(
                            index: _filter,
                            labels: [
                              'All (${store.tasks.length})',
                              'Due today (${store.dueToday.length})',
                            ],
                            onChanged: _setFilter,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text('Nothing is due today. Enjoy the rest.',
                                  style: TextStyle(color: p.textMuted)),
                            ),
                          ),
                        for (var i = 0; i < tasks.length; i++)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            // Cards slide up 16px with a 30ms stagger.
                            child: Entrance(
                              key: ValueKey('$_gen-${tasks[i].id}'),
                              delay: Motion.ms(60 + 30 * i),
                              duration: Motion.ms(420),
                              child: DashTaskCard(
                                key: ValueKey(tasks[i].id),
                                task: tasks[i],
                                store: store,
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Create habit',
        child: Squash(
          pressedScale: 0.92,
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: DashPalette.emerald,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: DashPalette.emerald.withAlpha(100),
                    blurRadius: 20,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
          ),
        ),
      );
}
