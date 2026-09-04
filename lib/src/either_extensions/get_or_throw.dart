import '../dart_either.dart';
import '../internal.dart';

/// Provide [getOrThrow] extension on [Either].
extension GetOrThrowEitherExtension<L extends Object, R> on Either<L, R> {
  /// Returns the [Right.value] if this [Either] is [Right], otherwise throws
  /// the [Left.value].
  /// This is functionally equivalent to `getOrHandle((value) => throw value)`.
  ///
  /// ### Example
  /// ```dart
  /// Right<StateError, int>(12).getOrThrow(); // Result: 12
  /// Left<StateError, int>(StateError('missing')).getOrThrow();
  /// // Throws StateError('missing')
  /// ```
  @covarianceSafe
  R getOrThrow() => switch (this) {
        Left(:final value) => throw value,
        Right(:final value) => value,
      };
}
