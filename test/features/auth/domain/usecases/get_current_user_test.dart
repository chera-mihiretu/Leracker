import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/core/usecases/usecase.dart';
import 'package:progress_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:progress_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:progress_tracker/features/auth/domain/usecases/get_current_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late GetCurrentUser useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUser(mockRepository);
  });

  const testUser = UserEntity(id: 'u1', email: 'user@test.com');

  test('returns user when authenticated', () async {
    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => const Right(testUser));

    final result = await useCase(const NoParams());

    expect(result, const Right(testUser));
  });

  test('returns null when no session', () async {
    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => const Right(null));

    final result = await useCase(const NoParams());

    expect(result, const Right(null));
  });

  test('returns failure on repository error', () async {
    const failure = ServerFailure(message: 'Error');
    when(() => mockRepository.getCurrentUser())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
  });
}

