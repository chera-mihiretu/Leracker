/// Base use case contract.
///
/// [T] is the return type on success.
/// [Params] is the input parameter object (use [NoParams] when none needed).
abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

/// Use when a use case requires no parameters.
class NoParams {
  const NoParams();
}
