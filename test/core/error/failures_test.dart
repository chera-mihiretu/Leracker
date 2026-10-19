import 'package:flutter_test/flutter_test.dart';
import 'package:progress_tracker/core/error/failures.dart';

void main() {
  group('Failures', () {
    test('ServerFailure supports value equality and toString', () {
      const failure1 = ServerFailure(message: 'Error', code: 500);
      const failure2 = ServerFailure(message: 'Error', code: 500);
      const failure3 = ServerFailure(message: 'Other', code: 400);

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
      expect(failure1.hashCode, equals(failure2.hashCode));
      expect(failure1.toString(), contains('Error'));
    });

    test('CacheFailure and NetworkFailure have default messages', () {
      const cacheFailure = CacheFailure();
      const networkFailure = NetworkFailure();

      expect(cacheFailure.message, 'Cache error occurred');
      expect(networkFailure.message, 'Network error occurred');
    });
  });
}
