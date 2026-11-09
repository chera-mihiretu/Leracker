import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dash_theme.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/filter_tabs.dart';

void main() {
  testWidgets('FilterTabs renders labels and switches index on tap',
      (tester) async {
    int selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashTheme(
            palette: DashPalette.dark,
            child: StatefulBuilder(
              builder: (context, setState) {
                return FilterTabs(
                  index: selected,
                  labels: const ['All (5)', 'Due today (2)'],
                  onChanged: (i) {
                    setState(() => selected = i);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('All (5)'), findsOneWidget);
    expect(find.text('Due today (2)'), findsOneWidget);

    // Tap on 'Due today (2)'
    await tester.tap(find.text('Due today (2)'));
    await tester.pumpAndSettle();

    expect(selected, 1);

    // Tap back on 'All (5)'
    await tester.tap(find.text('All (5)'));
    await tester.pumpAndSettle();

    expect(selected, 0);
  });
}

