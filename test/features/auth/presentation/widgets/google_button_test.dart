import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/auth/presentation/widgets/google_button.dart';

void main() {
  testWidgets('renders default label and G placeholder when idle',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleButton(
            busy: false,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders custom label and custom mark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleButton(
            busy: false,
            label: 'Sign In With Custom',
            mark: const Icon(Icons.star, key: Key('custom_mark')),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sign In With Custom'), findsOneWidget);
    expect(find.byKey(const Key('custom_mark')), findsOneWidget);
    expect(find.text('G'), findsNothing);
  });

  testWidgets('shows spinner and hides label when busy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoogleButton(
            busy: true,
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('triggers onTap and scales on press', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GoogleButton(
              busy: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    final gesture = await tester.startGesture(tester.getCenter(find.byType(GoogleButton)));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify scale down
    final animatedScale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(animatedScale.scale, 0.96);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tapped, isTrue);
  });
}
