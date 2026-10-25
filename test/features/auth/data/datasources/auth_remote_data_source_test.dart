import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:progress_tracker/features/auth/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockSupabaseClient extends Mock implements supabase.SupabaseClient {}
class MockGoTrueClient extends Mock implements supabase.GoTrueClient {}
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockSession extends Mock implements supabase.Session {}
class MockUser extends Mock implements supabase.User {}

void main() {
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
}

