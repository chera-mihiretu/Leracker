import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/core/usecases/usecase.dart';
import 'package:progress_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:progress_tracker/features/auth/domain/usecases/get_current_user.dart';
import 'package:progress_tracker/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:progress_tracker/features/auth/domain/usecases/sign_out.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:progress_tracker/features/auth/presentation/bloc/auth_state.dart';

class MockGetCurrentUser extends Mock implements GetCurrentUser {}
class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}
class MockSignOut extends Mock implements SignOut {}

void main() {
  late MockGetCurrentUser mockGetCurrentUser;
  late MockSignInWithGoogle mockSignInWithGoogle;
  late MockSignOut mockSignOut;
  late AuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockGetCurrentUser = MockGetCurrentUser();
    mockSignInWithGoogle = MockSignInWithGoogle();
    mockSignOut = MockSignOut();
    authBloc = AuthBloc(
      getCurrentUser: mockGetCurrentUser,
      signInWithGoogle: mockSignInWithGoogle,
      signOut: mockSignOut,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  const testUser = UserEntity(id: 'u1', email: 'test@example.com');

  test('initial state is AuthInitial', () {
    expect(authBloc.state, const AuthInitial());
  });

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when user is logged in',
      build: () {
        when(() => mockGetCurrentUser(any()))
            .thenAnswer((_) async => const Right(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const AuthLoading(),
        const Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when user is null',
      build: () {
        when(() => mockGetCurrentUser(any()))
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on failure',
      build: () {
        when(() => mockGetCurrentUser(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );
  });

  group('SignInWithGoogleRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful sign-in',
      build: () {
        when(() => mockSignInWithGoogle(any()))
            .thenAnswer((_) async => const Right(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SignInWithGoogleRequested()),
      expect: () => [
        const AuthLoading(),
        const Authenticated(testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailureState] on failed sign-in',
      build: () {
        when(() => mockSignInWithGoogle(any()))
            .thenAnswer((_) async => const Left(ServerFailure(message: 'Google Sign-in failed')));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SignInWithGoogleRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthFailureState('Google Sign-in failed'),
      ],
    );
  });

  group('SignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on sign-out',
      build: () {
        when(() => mockSignOut(any()))
            .thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [
        const AuthLoading(),
        const Unauthenticated(),
      ],
    );
  });
}
