/// Base use case contract.
///
/// [Type] is the return type on success.
/// [Params] is the input parameter object (use [NoParams] when none needed).
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// Use when a use case requires no parameters.
class NoParams {
  const NoParams();
}
