import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:progress_tracker/core/error/exceptions.dart';
import 'package:progress_tracker/core/error/failures.dart';
import 'package:progress_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:progress_tracker/features/auth/data/models/user_model.dart';
import 'package:progress_tracker/features/auth/data/repositories/auth_repository_impl.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  const testUserModel = UserModel(id: 'u1', email: 'test@example.com');

  group('signInWithGoogle', () {
    test('returns Right(UserModel) on success', () async {
      when(() => mockRemoteDataSource.signInWithGoogle())
          .thenAnswer((_) async => testUserModel);

      final result = await repository.signInWithGoogle();

      expect(result, const Right(testUserModel));
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockRemoteDataSource.signInWithGoogle())
          .thenThrow(const ServerException(message: 'Sign in cancelled'));

      final result = await repository.signInWithGoogle();

      expect(result, const Left(ServerFailure(message: 'Sign in cancelled')));
    });

    test('returns Left(ServerFailure) on unexpected exception', () async {
      when(() => mockRemoteDataSource.signInWithGoogle())
          .thenThrow(Exception('Unknown network error'));

      final result = await repository.signInWithGoogle();

      expect(result.isLeft(), isTrue);
    });
  });

  group('signOut', () {
    test('returns Right(null) on success', () async {
      when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, const Right(null));
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockRemoteDataSource.signOut())
          .thenThrow(const ServerException(message: 'Failed to sign out'));

      final result = await repository.signOut();

      expect(result, const Left(ServerFailure(message: 'Failed to sign out')));
    });
  });

  group('getCurrentUser', () {
    test('returns Right(UserModel) when user exists', () async {
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => testUserModel);

      final result = await repository.getCurrentUser();

      expect(result, const Right(testUserModel));
    });

    test('returns Right(null) when no user is logged in', () async {
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenAnswer((_) async => null);

      final result = await repository.getCurrentUser();

      expect(result, const Right(null));
    });

    test('returns Left(ServerFailure) on ServerException', () async {
      when(() => mockRemoteDataSource.getCurrentUser())
          .thenThrow(const ServerException(message: 'Failed'));

      final result = await repository.getCurrentUser();

      expect(result, const Left(ServerFailure(message: 'Failed')));
    });
  });
}

