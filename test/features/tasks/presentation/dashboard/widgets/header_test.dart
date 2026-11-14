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
    String? avatarUrl,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DashTheme(
          palette: DashPalette.dark,
          child: DashHeader(
            store: store,
            onReview: onReview ?? () {},
            userInitials: initials,
            userAvatarUrl: avatarUrl,
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

  group('DashAvatar', () {
    const testGoogleUrl =
        'https://lh3.googleusercontent.com/a/ACg8ocKgmpmOW-qSH90SR-Ao1JiHawppNGwM7yZx21ohBKctOzvi1rA=s96-c';

    testWidgets('renders fallback initials when avatarUrl is null or empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashAvatar(initials: 'CM', avatarUrl: null),
          ),
        ),
      );

      expect(find.text('CM'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders Image.network with Google picture url',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashAvatar(initials: 'CM', avatarUrl: testGoogleUrl),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect(image.image, isA<NetworkImage>());
      expect((image.image as NetworkImage).url, testGoogleUrl);
    });

    testWidgets(
        'DashHeader renders Google avatar and opens profile sheet with avatar',
        (tester) async {
      final store = DashboardStore();

      await tester.pumpWidget(
        buildWidget(
          store: store,
          initials: 'CM',
          avatarUrl: testGoogleUrl,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final avatarFinder = find.byType(DashAvatar);
      expect(avatarFinder, findsOneWidget);
      final headerAvatar = tester.widget<DashAvatar>(avatarFinder);
      expect(headerAvatar.avatarUrl, testGoogleUrl);

      // Tap avatar to open bottom sheet
      await tester.tap(avatarFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
      // Both header avatar and sheet avatar
      expect(find.byType(DashAvatar), findsNWidgets(2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
