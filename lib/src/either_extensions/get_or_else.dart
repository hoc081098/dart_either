import '../dart_either.dart';
import '../internal.dart';

/// Adds the deprecated `getOrElse` fallback to [Either].
extension GetOrElseEitherExtension<L, R> on Either<L, R> {
  /// Returns [Right.value] if this is a [Right]. If this is a [Left], invokes
  /// [defaultValue] and returns its result.
  ///
  /// [defaultValue] is invoked exactly once for a [Left] and is not invoked for
  /// a [Right]. This differs from `getOrDefault`, whose fallback value is
  /// evaluated before the call.
  ///
  /// Prefer `getOrDefault(value)` for eager fallback values or
  /// `getOrHandle((left) => value)` for lazy, left-aware computation.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final int fromRight = Right<String, int>(12).getOrElse(() => 17);    // 12
  /// final int fromLeft = Left<String, int>('error').getOrElse(() => 17); // 17
  /// ```
  @covarianceSafe
  @Deprecated(
    'Use getOrDefault(value) for eager fallback, or getOrHandle for lazy fallback. '
    'It will be removed in v3.',
  )
  R getOrElse(R Function() defaultValue) => switch (this) {
        Left() => defaultValue(),
        Right(value: final value) => value,
      };
}
