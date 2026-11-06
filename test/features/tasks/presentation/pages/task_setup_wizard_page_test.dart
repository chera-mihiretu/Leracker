import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:progress_tracker/features/tasks/presentation/pages/task_setup_wizard_page.dart';

class MockTasksBloc extends MockBloc<TasksEvent, TasksState> implements TasksBloc {}

void main() {
  late MockTasksBloc mockTasksBloc;

  setUpAll(() {
    registerFallbackValue(const AddTaskSubmitted(name: 'fallback'));
  });

  setUp(() {
    mockTasksBloc = MockTasksBloc();
    when(() => mockTasksBloc.state).thenReturn(
      const TasksLoaded(tasks: [], entriesByTaskId: {}),
    );
  });

  Widget buildWidget() {
    return BlocProvider<TasksBloc>.value(
      value: mockTasksBloc,
      child: const MaterialApp(
        home: TaskSetupWizardPage(),
      ),
    );
  }

  group('TaskSetupWizardPage', () {
    testWidgets('Step 1: Continue button disabled when empty, enabled when name entered', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Heading exists
      expect(find.textContaining('What habit or goal'), findsOneWidget);

      // Continue button should be disabled
      final continueBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continue'),
      );
      expect(continueBtn.onPressed, isNull);

      // Enter a name
      await tester.enterText(find.byType(TextField), 'Read 20 pages');
      await tester.pump();

      // Continue button should now be enabled
      final enabledBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continue'),
      );
      expect(enabledBtn.onPressed, isNotNull);
    });

    testWidgets('Step 1: Tapping a suggested habit chip sets the text', (tester) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.text('Workout'));
      await tester.pump();

      expect(find.text('Workout'), findsNWidgets(2)); // in chip & text field
    });

    testWidgets('Step 2: Frequency selector switches between Daily, Weekly, and Monthly', (tester) async {
      await tester.pumpWidget(buildWidget());

      // Advance to Step 2
      await tester.enterText(find.byType(TextField), 'Workout');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      // Check Step 2 title
      expect(find.textContaining('How often do you want'), findsOneWidget);

      // Switch to Weekly
      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pick exactly one day'), findsOneWidget);

      // Switch to Monthly
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Monthly schedule rule'), findsOneWidget);
    });

    testWidgets('Complete 6-step flow dispatches single AddTaskSubmitted at the end', (tester) async {
      await tester.pumpWidget(buildWidget());

      // ── Step 1: Identity ──
      await tester.enterText(find.byType(TextField), 'Meditation');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      verifyNever(() => mockTasksBloc.add(any()));

      // ── Step 2: Repetition (select Daily) ──
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      verifyNever(() => mockTasksBloc.add(any()));

      // ── Step 3: Start Time ──
      expect(find.textContaining('When is your ideal'), findsOneWidget);
      await tester.tap(find.text('Morning (08:00)'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      verifyNever(() => mockTasksBloc.add(any()));

      // ── Step 4: Notification Budget ──
      expect(find.textContaining('How many reminders'), findsOneWidget);
      await tester.tap(find.text('2 — Gentle Follow-up'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      verifyNever(() => mockTasksBloc.add(any()));

      // ── Step 5: Grid Color ──
      expect(find.textContaining('Choose the color'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      verifyNever(() => mockTasksBloc.add(any()));

      // ── Step 6: Review & Final Confirmation ──
      expect(find.textContaining('Ready to start'), findsOneWidget);
      expect(find.text('Meditation'), findsOneWidget);

      // Tap final submit
      await tester.tap(find.text('Create Habit & Start Grid'));
      await tester.pump();

      // Verifies exactly ONE request was dispatched at the end
      verify(() => mockTasksBloc.add(any(that: isA<AddTaskSubmitted>())))
          .called(1);
    });
  });
}

