import 'package:flutter/material.dart';

import '../../task_setup/motion.dart';
import '../dash_theme.dart';

/// [ All (6) ] [ Due today (4) ] with a sliding pill.
class FilterTabs extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = DashTheme.of(context);
    return LayoutBuilder(builder: (context, box) {
      final segW = box.maxWidth / labels.length;
      return AnimatedContainer(
        duration: Motion.ms(300),
        height: 42,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: p.border),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Motion.ms(300),
              curve: Motion.spring,
              left: index * segW + 3,
              top: 3,
              bottom: 3,
              width: segW - 6,
              child: Container(
                decoration: BoxDecoration(
                  color: p.isDark ? p.border : p.text,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.ms(200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: i == index
                                ? (p.isDark ? p.text : p.card)
                                : p.textMuted,
                          ),
                          child: Text(labels[i]),
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
