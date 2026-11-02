import 'package:flutter/material.dart';

import '../motion.dart';
import '../task_draft.dart';
import 'contribution_grid.dart';

const kNewTaskHeroTag = 'new-task-card';

/// The task card shown on the review page and at the top of the task list.
/// Wrapped in a Hero so the review card morphs into the list card.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.draft, this.highlight = 0});

  final TaskDraft draft;

  /// 0..1 emerald glow around the card (used when it lands in the list).
  final double highlight;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: kNewTaskHeroTag,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: PT.slate,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: fade(draft.color, 0.25 + 0.5 * highlight)),
            boxShadow: [
              BoxShadow(
                color: fade(draft.color, 0.35 * highlight),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                draft.name.isEmpty ? 'Untitled habit' : draft.name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    color: PT.text),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Badge(text: draft.scheduleLabel, color: draft.color),
                  const SizedBox(width: 8),
                  const Icon(Icons.schedule_rounded,
                      size: 16, color: PT.textMuted),
                  const SizedBox(width: 4),
                  Text(draft.timeLabel,
                      style: const TextStyle(
                          fontSize: 14,
                          color: PT.textMuted,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ),
              const SizedBox(height: 16),
              ContributionGrid(color: draft.color, height: 84),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: fade(color, 0.15),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: color)),
      );
}
