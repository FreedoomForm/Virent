/// Abstract use case contract used across the Virent application.
///
/// Follows the Clean Architecture "use case" pattern: every use case
/// declares the [Type] it returns and the [Params] it accepts. Use cases
/// orchestrate domain logic and are the single entry point used by the
/// presentation layer (providers / controllers) to talk to repositories.
///
/// Concrete use cases implement [call] and may accept `null` params when no
/// input is required (e.g. a "fetch current user" use case).
///
/// Ported from BarqScoot's `core/usecases/usecase.dart` and adapted to
/// Virent's naming conventions.
abstract class UseCase<Type, Params> {
  /// Executes the use case.
  ///
  /// [params] is optional so that use cases which do not require input can
  /// be invoked with `call()` instead of `call(params: null)`.
  Future<Type> call({Params? params});
}

/// Marker interface for use cases that do not require any parameters.
///
/// Implementations can use `Future<Type> call()` directly. Provided for
/// documentation and to keep the call sites self-explanatory.
abstract class NoParamsUseCase<Type> {
  Future<Type> call();
}
