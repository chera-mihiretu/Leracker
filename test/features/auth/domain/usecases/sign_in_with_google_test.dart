import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/core/usecases/usecase.dart';
import 'package:progress_tracker/features/auth/domain/entities/user_entity.dart';
import 'package:progress_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:progress_tracker/features/auth/domain/usecases/sign_in_with_google.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignInWithGoogle useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithGoogle(mockRepository);
  });

  const testUser = UserEntity(id: 'u1', email: 'user@test.com');

  test('returns UserEntity on success', () async {
    when(() => mockRepository.signInWithGoogle())
        .thenAnswer((_) async => const Right(testUser));

    final result = await useCase(const NoParams());

    expect(result, const Right(testUser));
    verify(() => mockRepository.signInWithGoogle()).called(1);
  });

  test('returns ServerFailure on error', () async {
    const failure = ServerFailure(message: 'Sign in failed');
    when(() => mockRepository.signInWithGoogle())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
    verify(() => mockRepository.signInWithGoogle()).called(1);
  });
}

