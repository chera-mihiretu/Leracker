import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supabase.SupabaseClient supabaseClient;
  final GoogleSignIn googleSignIn;

  AuthRemoteDataSourceImpl({
    required this.supabaseClient,
    required this.googleSignIn,
  });

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const ServerException(message: 'Google sign-in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const ServerException(
          message: 'Missing ID Token from Google. Make sure GOOGLE_WEB_CLIENT_ID in your .env contains your Web Client ID (not Android Client ID).',
        );
      }

      final response = await supabaseClient.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user == null) {
        throw const ServerException(message: 'Failed to sign in with Supabase');
      }

      return UserModel.fromSupabaseUser(user);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        supabaseClient.auth.signOut(),
        googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final session = supabaseClient.auth.currentSession;
    if (session == null) return null;
    return UserModel.fromSupabaseUser(session.user);
  }
}

