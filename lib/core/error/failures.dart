import 'package:flutter/foundation.dart';

/// Base failure class for the domain layer.
/// All feature-specific failures should extend this.
@immutable
abstract class Failure {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  String toString() => 'Failure(message: $message, code: $code)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure && message == other.message && code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred', super.code});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred', super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Network error occurred', super.code});
}

