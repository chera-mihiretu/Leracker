import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/exceptions.dart';
import 'package:progress_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:progress_tracker/features/auth/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}
class MockGoogleSignInAuthentication extends Mock implements GoogleSignInAuthentication {}
class MockAuthResponse extends Mock implements supabase.AuthResponse {}
class MockSession extends Mock implements supabase.Session {}
class MockUser extends Mock implements supabase.User {}

void main() {
  setUpAll(() {
    registerFallbackValue(supabase.OAuthProvider.google);
  });

  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late MockGoogleSignIn mockGoogleSignIn;
  late AuthRemoteDataSourceImpl dataSource;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    mockGoogleSignIn = MockGoogleSignIn();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);

    dataSource = AuthRemoteDataSourceImpl(
      supabaseClient: mockSupabaseClient,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('getCurrentUser', () {
    test('returns UserModel when active session exists via currentSession', () async {
      final mockSession = MockSession();
      final mockUser = MockUser();

      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockUser.email).thenReturn('user@example.com');
      when(() => mockUser.userMetadata).thenReturn({'full_name': 'Test User'});

      when(() => mockSession.user).thenReturn(mockUser);
      when(() => mockGoTrueClient.currentSession).thenReturn(mockSession);

      final result = await dataSource.getCurrentUser();

      expect(result, isA<UserModel>());
      expect(result?.id, 'user-123');
      expect(result?.email, 'user@example.com');
      expect(result?.displayName, 'Test User');
      verify(() => mockGoTrueClient.currentSession).called(1);
    });

    test('returns null when currentSession is null (unauthenticated)', () async {
      when(() => mockGoTrueClient.currentSession).thenReturn(null);

      final result = await dataSource.getCurrentUser();

      expect(result, isNull);
      verify(() => mockGoTrueClient.currentSession).called(1);
    });
  });

  group('signOut', () {
    test('calls signOut on both supabaseClient and googleSignIn', () async {
      when(() => mockGoTrueClient.signOut()).thenAnswer((_) async {});
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

      await dataSource.signOut();

      verify(() => mockGoTrueClient.signOut()).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
    });
  });

  group('signInWithGoogle', () {
    late MockGoogleSignInAccount mockGoogleUser;
    late MockGoogleSignInAuthentication mockGoogleAuth;
    late MockAuthResponse mockAuthResponse;
    late MockUser mockUser;

    setUp(() {
      mockGoogleUser = MockGoogleSignInAccount();
      mockGoogleAuth = MockGoogleSignInAuthentication();
      mockAuthResponse = MockAuthResponse();
      mockUser = MockUser();
    });

    test('successfully signs in with Google, calls Supabase signInWithIdToken, and returns UserModel', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
      when(() => mockGoogleUser.authentication).thenAnswer((_) async => mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn('test-id-token');
      when(() => mockGoogleAuth.accessToken).thenReturn('test-access-token');

      when(() => mockGoTrueClient.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: 'test-id-token',
        accessToken: 'test-access-token',
      )).thenAnswer((_) async => mockAuthResponse);

      when(() => mockAuthResponse.user).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockUser.email).thenReturn('cheramihiretu@gmail.com');
      when(() => mockUser.userMetadata).thenReturn({
        'full_name': 'Chera Mihiretu',
        'avatar_url': 'https://lh3.googleusercontent.com/avatar.jpg',
      });

      final result = await dataSource.signInWithGoogle();

      expect(result, isA<UserModel>());
      expect(result.id, 'user-123');
      expect(result.email, 'cheramihiretu@gmail.com');
      expect(result.displayName, 'Chera Mihiretu');
      expect(result.avatarUrl, 'https://lh3.googleusercontent.com/avatar.jpg');

      verify(() => mockGoogleSignIn.signIn()).called(1);
      verify(() => mockGoTrueClient.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: 'test-id-token',
        accessToken: 'test-access-token',
      )).called(1);
    });

    test('throws ServerException with cancellation message when user cancels Google sign-in', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

      expect(
        () => dataSource.signInWithGoogle(),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', 'Google sign-in was cancelled')),
      );

      verify(() => mockGoogleSignIn.signIn()).called(1);
      verifyNever(() => mockGoTrueClient.signInWithIdToken(
        provider: any(named: 'provider'),
        idToken: any(named: 'idToken'),
        accessToken: any(named: 'accessToken'),
      ));
    });

    test('throws ServerException when Google authentication returns null idToken', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
      when(() => mockGoogleUser.authentication).thenAnswer((_) async => mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn(null);
      when(() => mockGoogleAuth.accessToken).thenReturn('test-access-token');

      expect(
        () => dataSource.signInWithGoogle(),
        throwsA(isA<ServerException>().having(
          (e) => e.message,
          'message',
          contains('Missing ID Token from Google'),
        )),
      );

      verifyNever(() => mockGoTrueClient.signInWithIdToken(
        provider: any(named: 'provider'),
        idToken: any(named: 'idToken'),
        accessToken: any(named: 'accessToken'),
      ));
    });

    test('throws ServerException when Supabase auth returns null user', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
      when(() => mockGoogleUser.authentication).thenAnswer((_) async => mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn('test-id-token');
      when(() => mockGoogleAuth.accessToken).thenReturn('test-access-token');

      when(() => mockGoTrueClient.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: 'test-id-token',
        accessToken: 'test-access-token',
      )).thenAnswer((_) async => mockAuthResponse);
      when(() => mockAuthResponse.user).thenReturn(null);

      expect(
        () => dataSource.signInWithGoogle(),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', 'Failed to sign in with Supabase')),
      );
    });

    test('throws ServerException when Supabase signInWithIdToken throws exception', () async {
      when(() => mockGoogleSignIn.signIn()).thenAnswer((_) async => mockGoogleUser);
      when(() => mockGoogleUser.authentication).thenAnswer((_) async => mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn('test-id-token');
      when(() => mockGoogleAuth.accessToken).thenReturn('test-access-token');

      when(() => mockGoTrueClient.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: 'test-id-token',
        accessToken: 'test-access-token',
      )).thenThrow(const supabase.AuthException('OAuth error'));

      expect(
        () => dataSource.signInWithGoogle(),
        throwsA(isA<ServerException>().having((e) => e.message, 'message', contains('OAuth error'))),
      );
    });
  });
}

