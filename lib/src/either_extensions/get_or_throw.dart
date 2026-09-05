import '../dart_either.dart';
import '../internal.dart';

/// Adds [getOrThrow] to [Either].
extension GetOrThrowEitherExtension<L extends Object, R> on Either<L, R> {
  /// Returns [Right.value] if this is a [Right]. If this is a [Left], throws
  /// [Left.value].
  ///
  /// This is equivalent to `getOrHandle((value) => throw value)`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final int value = Right<StateError, int>(12).getOrThrow(); // 12
  ///
  /// Left<StateError, int>(StateError('missing')).getOrThrow();
  /// // Throws StateError('missing')
  /// ```
  @covarianceSafe
  R getOrThrow() => switch (this) {
        Left(:final value) => throw value,
        Right(:final value) => value,
      };
}
