import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/presentation/widgets/progress_tracker_logo.dart';
import 'package:progress_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:progress_tracker/features/auth/presentation/pages/sign_in_page.dart';
import 'package:progress_tracker/features/auth/presentation/pages/splash_page.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_event.dart';
import 'package:progress_tracker/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:progress_tracker/features/tasks/presentation/pages/tasks_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockTasksBloc extends MockBloc<TasksEvent, TasksState> implements TasksBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockTasksBloc mockTasksBloc;

  const testUser = UserEntity(
    id: 'user-123',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  setUpAll(() {
    registerFallbackValue(const LoadTasksRequested());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockTasksBloc = MockTasksBloc();
    when(() => mockTasksBloc.state).thenReturn(
      const TasksLoaded(tasks: [], entriesByTaskId: {}),
    );
  });

  Widget buildWidget({bool animate = false, double speed = 1.0}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<TasksBloc>.value(value: mockTasksBloc),
      ],
      child: MaterialApp(
        home: SplashPage(animate: animate, speed: speed),
      ),
    );
  }

  group('SplashPage', () {
    testWidgets('renders animated logo and app title correctly', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(buildWidget(animate: true, speed: 1.0));

      expect(find.text('Progress Tracker'), findsOneWidget);
      expect(find.text('Build your wall of green.'), findsOneWidget);
      expect(find.byType(ProgressTrackerLogo), findsOneWidget);
    });

    testWidgets('routes to TasksPage when state transitions to Authenticated', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([const Authenticated(testUser)]),
      );

      await tester.pumpWidget(buildWidget(animate: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TasksPage), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });

    testWidgets('routes to SignInPage when state transitions to Unauthenticated', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([const Unauthenticated()]),
      );

      await tester.pumpWidget(buildWidget(animate: false));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });

    testWidgets('routes to SignInPage when state transitions to AuthFailureState', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());
      whenListen(
        mockAuthBloc,
        Stream.fromIterable([const AuthFailureState('Session expired')]),
      );

      await tester.pumpWidget(buildWidget(animate: false));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });

    testWidgets('routes to TasksPage immediately if already Authenticated on mount', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const Authenticated(testUser));

      await tester.pumpWidget(buildWidget(animate: false));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TasksPage), findsOneWidget);
    });

    testWidgets('routes to SignInPage immediately if already Unauthenticated on mount', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());

      await tester.pumpWidget(buildWidget(animate: false));
      await tester.pumpAndSettle();

      expect(find.byType(SignInPage), findsOneWidget);
    });

    testWidgets('waits for animation completion before navigating when animate is true', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const Authenticated(testUser));

      await tester.pumpWidget(buildWidget(animate: true, speed: 1.0));

      // At 1.0s, animation is still playing, TasksPage should not be pushed yet
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(TasksPage), findsNothing);

      // Advance past 2.5s (completion)
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TasksPage), findsOneWidget);
      expect(find.byType(SplashPage), findsNothing);
    });
  });
}
