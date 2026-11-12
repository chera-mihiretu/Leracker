import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:progress_tracker/features/tasks/domain/entities/task_entity.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/dashboard_screen.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/hero_pulse.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/task_card.dart';
import 'package:progress_tracker/features/tasks/presentation/dashboard/widgets/zero_state.dart';
import 'package:progress_tracker/features/tasks/presentation/pages/tasks_page.dart';
import 'package:progress_tracker/features/tasks/presentation/task_setup/task_setup_flow.dart';

class MockTasksBloc extends MockBloc<TasksEvent, TasksState>
    implements TasksBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockTasksBloc mockTasksBloc;
  late MockAuthBloc mockAuthBloc;

  setUpAll(() {
    registerFallbackValue(const LoadTasksRequested());
    registerFallbackValue(const AddTaskSubmitted(name: 'fallback'));
    registerFallbackValue(const SignOutRequested());
  });

  setUp(() {
    mockTasksBloc = MockTasksBloc();
    mockAuthBloc = MockAuthBloc();
    when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());
  });

  Widget buildWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TasksBloc>.value(value: mockTasksBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
      ],
      child: const MaterialApp(
        home: TasksPage(),
      ),
    );
  }

  final testTask = TaskEntity(
    id: 't1',
    userId: 'u1',
    name: 'Learn Flutter',
    frequencyType: 'daily',
    daysOfWeek: const [1, 2, 3, 4, 5, 6, 7],
    gridColor: '#22C55E',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  testWidgets('shows loading indicator when state is TasksLoading',
      (tester) async {
    when(() => mockTasksBloc.state).thenReturn(const TasksLoading());

    await tester.pumpWidget(buildWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error and retry button when state is TasksError',
      (tester) async {
    when(() => mockTasksBloc.state)
        .thenReturn(const TasksError('Something failed'));

    await tester.pumpWidget(buildWidget());

    expect(find.text('Error: Something failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    verify(() => mockTasksBloc.add(const LoadTasksRequested()))
        .called(greaterThanOrEqualTo(1));
  });

  testWidgets('shows empty zero state when tasks list is empty',
      (tester) async {
    when(() => mockTasksBloc.state).thenReturn(const TasksLoaded(
      tasks: [],
      entriesByTaskId: {},
    ));

    await tester.pumpWidget(buildWidget());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(ZeroState), findsOneWidget);
    expect(find.text('Create your first habit'), findsOneWidget);
  });

  testWidgets('renders task card and hero pulse when tasks exist',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockTasksBloc.state).thenReturn(TasksLoaded(
      tasks: [testTask],
      entriesByTaskId: const {},
    ));

    await tester.pumpWidget(buildWidget());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(HeroPulse), findsOneWidget);
    expect(find.byType(DashTaskCard), findsOneWidget);
    expect(find.text('Learn Flutter'), findsOneWidget);
    expect(find.text('HABITS'), findsOneWidget);
  });

  testWidgets('tapping Create your first habit in zero state opens TaskSetupFlow',
      (tester) async {
    when(() => mockTasksBloc.state).thenReturn(const TasksLoaded(
      tasks: [],
      entriesByTaskId: {},
    ));

    await tester.pumpWidget(buildWidget());
    await tester.pump(const Duration(milliseconds: 500));

    final createButton = find.text('Create your first habit');
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TaskSetupFlow), findsOneWidget);
    expect(find.textContaining('What habit or goal'), findsOneWidget);
  });

  testWidgets('tapping avatar opens profile sheet and allows sign out',
      (tester) async {
    when(() => mockTasksBloc.state).thenReturn(const TasksLoaded(
      tasks: [],
      entriesByTaskId: {},
    ));

    await tester.pumpWidget(buildWidget());
    await tester.pump(const Duration(milliseconds: 500));

    final avatar = find.text('PT');
    expect(avatar, findsOneWidget);
    await tester.tap(avatar);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verify(() => mockAuthBloc.add(const SignOutRequested())).called(1);
  });
}
