import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/core/presentation/widgets/progress_tracker_logo.dart';

void main() {
  testWidgets('intro fires onCompleted after 2.5s', (tester) async {
    var done = false;
    await tester.pumpWidget(MaterialApp(
      home: Center(child: ProgressTrackerLogo(onCompleted: () => done = true)),
    ));
    await tester.pump(const Duration(milliseconds: 1000));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(done, isTrue);
  });

  testWidgets('all modes render without errors', (tester) async {
    for (final mode in ProgressLogoMode.values) {
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: ProgressTrackerLogo(mode: mode, showBackground: true),
        ),
      ));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('splash calls onFinished', (tester) async {
    var finished = false;
    await tester.pumpWidget(MaterialApp(
      home: ProgressTrackerSplash(onFinished: () => finished = true),
    ));
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(finished, isTrue);
  });
}
