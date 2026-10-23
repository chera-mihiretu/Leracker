import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserEntity', () {
    test('supports value equality based on props', () {
      const user1 = UserEntity(
        id: 'u1',
        email: 'test@example.com',
        displayName: 'Test User',
        avatarUrl: 'https://example.com/avatar.png',
      );
      const user2 = UserEntity(
        id: 'u1',
        email: 'test@example.com',
        displayName: 'Test User',
        avatarUrl: 'https://example.com/avatar.png',
      );
      const user3 = UserEntity(id: 'u2', email: 'other@example.com');

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
      expect(user1.props, ['u1', 'test@example.com', 'Test User', 'https://example.com/avatar.png']);
    });
  });
}

