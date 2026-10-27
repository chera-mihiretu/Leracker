import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:progress_tracker/features/auth/presentation/pages/sign_in_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const SignInPage(),
      ),
    );
  }

  testWidgets('renders title and Continue with Google button', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());

    await tester.pumpWidget(buildWidget());

    expect(find.text('Progress Tracker'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('shows loading indicator when state is AuthLoading', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(const AuthLoading());

    await tester.pumpWidget(buildWidget());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('dispatches SignInWithGoogleRequested on button tap', (tester) async {
    when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());

    await tester.pumpWidget(buildWidget());
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    verify(() => mockAuthBloc.add(const SignInWithGoogleRequested())).called(1);
  });
}

