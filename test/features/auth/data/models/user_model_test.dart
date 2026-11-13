import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/features/auth/data/models/user_model.dart';
import 'package:progress_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class MockUser extends Mock implements supabase.User {}

void main() {
  group('UserModel', () {
    const testModel = UserModel(
      id: '123',
      email: 'alex@example.com',
      displayName: 'Alex',
      avatarUrl: 'https://example.com/alex.jpg',
    );

    test('is a subclass of UserEntity', () {
      expect(testModel, isA<UserEntity>());
    });

    test('fromJson deserializes json map correctly', () {
      final json = {
        'id': '123',
        'email': 'alex@example.com',
        'display_name': 'Alex',
        'avatar_url': 'https://example.com/alex.jpg',
      };

      final result = UserModel.fromJson(json);

      expect(result, equals(testModel));
    });

    test('fromJson handles raw_user_meta_data from Google correctly', () {
      final googleMetadata = {
        'iss': 'https://accounts.google.com',
        'sub': '114254638465006499920',
        'name': 'Chera Mihiretu',
        'email': 'cheramihiretu@gmail.com',
        'picture':
            'https://lh3.googleusercontent.com/a/ACg8ocKgmpmOW-qSH90SR-Ao1JiHawppNGwM7yZx21ohBKctOzvi1rA=s96-c',
        'full_name': 'Chera Mihiretu',
        'avatar_url':
            'https://lh3.googleusercontent.com/a/ACg8ocKgmpmOW-qSH90SR-Ao1JiHawppNGwM7yZx21ohBKctOzvi1rA=s96-c',
        'provider_id': '114254638465006499920',
        'email_verified': true,
        'phone_verified': false,
      };

      final json = {
        'id': 'user-chera',
        'email': 'cheramihiretu@gmail.com',
        'raw_user_meta_data': googleMetadata,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user-chera');
      expect(user.email, 'cheramihiretu@gmail.com');
      expect(user.displayName, 'Chera Mihiretu');
      expect(
        user.avatarUrl,
        'https://lh3.googleusercontent.com/a/ACg8ocKgmpmOW-qSH90SR-Ao1JiHawppNGwM7yZx21ohBKctOzvi1rA=s96-c',
      );
    });

    test('fromSupabaseUser extracts avatarUrl and name from Google userMetadata', () {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-google-1');
      when(() => mockUser.email).thenReturn('cheramihiretu@gmail.com');
      when(() => mockUser.userMetadata).thenReturn({
        'iss': 'https://accounts.google.com',
        'sub': '114254638465006499920',
        'name': 'Chera Mihiretu',
        'email': 'cheramihiretu@gmail.com',
        'picture':
            'https://lh3.googleusercontent.com/a/ACg8ocKgmpmOW-qSH90SR-Ao1JiHawppNGwM7yZx21ohBKctOzvi1rA=s96-c',
        'full_name': 'Chera Mihiretu',
        'avatar_url':
            'https://lh3.googleusercontent.com/a/ACg8ocKgmpmOW-qSH90SR-Ao1JiHawppNGwM7yZx21ohBKctOzvi1rA=s96-c',
        'provider_id': '114254638465006499920',
        'email_verified': true,
        'phone_verified': false,
      });

      final user = UserModel.fromSupabaseUser(mockUser);

      expect(user.id, 'user-google-1');
      expect(user.email, 'cheramihiretu@gmail.com');
      expect(user.displayName, 'Chera Mihiretu');
      expect(
        user.avatarUrl,
        'https://lh3.googleusercontent.com/a/ACg8ocKgmpmOW-qSH90SR-Ao1JiHawppNGwM7yZx21ohBKctOzvi1rA=s96-c',
      );
    });

    test('fromSupabaseUser falls back to picture when avatar_url is missing', () {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-google-2');
      when(() => mockUser.email).thenReturn('cheramihiretu@gmail.com');
      when(() => mockUser.userMetadata).thenReturn({
        'name': 'Chera Mihiretu',
        'picture': 'https://lh3.googleusercontent.com/picture_only.jpg',
      });

      final user = UserModel.fromSupabaseUser(mockUser);

      expect(user.displayName, 'Chera Mihiretu');
      expect(user.avatarUrl, 'https://lh3.googleusercontent.com/picture_only.jpg');
    });

    test('toJson serializes model to json map correctly', () {
      final result = testModel.toJson();

      expect(result, {
        'id': '123',
        'email': 'alex@example.com',
        'display_name': 'Alex',
        'avatar_url': 'https://example.com/alex.jpg',
      });
    });
  });
}

