// Destination after setup: the new task card is already resting at the top.
import 'package:flutter/material.dart';

import 'motion.dart';
import 'task_draft.dart';
import 'widgets/entrance.dart';
import 'widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.newTask});
  final TaskDraft newTask;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with SingleTickerProviderStateMixin {
  // Soft glow on the new card that fades after it lands.
  late final AnimationController _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..forward();

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PT.obsidian,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            const Text('Today',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                    color: PT.text)),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _glow,
              builder: (context, _) => TaskCard(
                draft: widget.newTask,
                highlight: 1 - Curves.easeOut.transform(_glow.value),
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < 2; i++)
              Entrance(
                delay: Motion.ms(300 + 60 * i),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _PlaceholderTask(
                      title: i == 0 ? 'Drink water' : 'Journal'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTask extends StatelessWidget {
  const _PlaceholderTask({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PT.slate,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: PT.textMuted)),
            ),
            const Icon(Icons.check_circle_rounded, color: PT.emerald),
          ],
        ),
      );
}
