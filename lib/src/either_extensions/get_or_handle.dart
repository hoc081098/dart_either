import '../dart_either.dart';
import '../internal.dart';

/// Provides [getOrHandle] on [Either] without crossing a covariant
/// instance-method boundary.
extension GetOrHandleEitherExtension<L, R> on Either<L, R> {
  /// Returns the [Right.value], or allows [defaultValue] to transform the
  /// [Left.value] into the final result.
  ///
  /// [defaultValue] is invoked exactly once only when this is a [Left].
  /// Exceptions thrown by [defaultValue] are not caught.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).getOrHandle((v) => 17);   // Result: 12
  /// Left<int, int>(12).getOrHandle((v) => v + 5); // Result: 17
  /// ```
  @covarianceSafe
  R getOrHandle(R Function(L value) defaultValue) => switch (this) {
        Left(value: final value) => defaultValue(value),
        Right(value: final value) => value,
      };
}
