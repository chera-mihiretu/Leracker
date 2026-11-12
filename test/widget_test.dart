import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/injection.dart';
import 'package:progress_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await initInjection();
  });

  testWidgets('App renders splash screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const ProgressTrackerApp());
    expect(find.text('Progress Tracker'), findsOneWidget);
  });
}
