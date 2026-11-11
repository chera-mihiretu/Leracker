import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dash_theme.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/zero_state.dart';

void main() {
  testWidgets('ZeroState renders illustration, quote, and handles onCreate tap',
      (tester) async {
    var created = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashTheme(
            palette: DashPalette.dark,
            child: ZeroState(
              onCreate: () => created = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('Small consistent steps compound'),
      findsOneWidget,
    );
    expect(find.text('Create your first habit'), findsOneWidget);

    await tester.tap(find.text('Create your first habit'));
    await tester.pump();

    expect(created, isTrue);

    // Tear down
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
