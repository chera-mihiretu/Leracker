import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dash_theme.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dashboard_store.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/task_item.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/header.dart';
import 'package:progress_tracker/features/tasks/presentation/task_setup/pages/review_page.dart'
    show FluidToggle;

void main() {
  final today = dateOnly(DateTime.now());
  final yesterday = addDays(today, -1);

  Widget buildWidget({
    required DashboardStore store,
    VoidCallback? onReview,
    VoidCallback? onSignOut,
    String initials = 'CK',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DashTheme(
          palette: DashPalette.dark,
          child: DashHeader(
            store: store,
            onReview: onReview ?? () {},
            userInitials: initials,
            onSignOut: onSignOut,
          ),
        ),
      ),
    );
  }

  testWidgets('DashHeader renders greeting, date, and user initials',
      (tester) async {
    final store = DashboardStore();

    await tester.pumpWidget(buildWidget(store: store, initials: 'JD'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Today\'s focus'), findsOneWidget);
    expect(find.text('JD'), findsOneWidget);
    expect(find.byType(ReviewPill), findsNothing);
  });

  testWidgets('DashHeader shows ReviewPill and triggers onReview when items pending',
      (tester) async {
    final task = TaskItem(
      id: 'rev',
      name: 'Review Needed',
      gridColor: const Color(0xFF22C55E),
      createdAt: addDays(today, -10),
      includeInMorningReview: true,
      daysOfWeek: {yesterday.weekday - 1}, // was due yesterday
    );
    final store = DashboardStore(tasks: [task]);

    var reviewTapped = false;
    await tester.pumpWidget(
      buildWidget(
        store: store,
        onReview: () => reviewTapped = true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('1 to review'), findsOneWidget);

    await tester.tap(find.text('1 to review'));
    await tester.pump();

    expect(reviewTapped, isTrue);
  });

  testWidgets('Avatar tap opens profile bottom sheet with dark mode and sign out',
      (tester) async {
    final store = DashboardStore();
    var signedOut = false;

    await tester.pumpWidget(
      buildWidget(
        store: store,
        initials: 'AB',
        onSignOut: () => signedOut = true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap avatar
    await tester.tap(find.text('AB'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    // Toggle theme
    expect(store.isDark, isTrue);
    await tester.tap(find.byType(FluidToggle));
    await tester.pump();
    expect(store.isDark, isFalse);

    // Sign out
    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(signedOut, isTrue);

    // Tear down
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
