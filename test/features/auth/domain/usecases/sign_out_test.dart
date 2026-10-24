import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/core/usecases/usecase.dart';
import 'package:progress_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:progress_tracker/features/auth/domain/usecases/sign_out.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignOut useCase;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOut(mockRepository);
  });

  test('returns Right(null) on success', () async {
    when(() => mockRepository.signOut())
        .thenAnswer((_) async => const Right(null));

    final result = await useCase(const NoParams());

    expect(result, const Right(null));
    verify(() => mockRepository.signOut()).called(1);
  });

  test('returns Left(ServerFailure) on failure', () async {
    const failure = ServerFailure(message: 'Sign out failed');
    when(() => mockRepository.signOut())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
    verify(() => mockRepository.signOut()).called(1);
  });
}

