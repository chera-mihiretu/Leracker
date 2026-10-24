import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/auth/data/models/user_model.dart';
import 'package:progress_tracker/features/auth/domain/entities/user_entity.dart';

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

