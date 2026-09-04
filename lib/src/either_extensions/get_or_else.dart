import '../dart_either.dart';
import '../internal.dart';

/// Provides the deprecated lazy `getOrElse` fallback on [Either] without
/// crossing a covariant instance-method boundary.
extension GetOrElseEitherExtension<L, R> on Either<L, R> {
  /// Returns the [Right.value], or lazily computes a fallback for [Left].
  ///
  /// This preserves the historical lazy behavior: [defaultValue] is invoked
  /// only when this is a [Left]. It is not equivalent to `getOrDefault`, whose
  /// fallback value is evaluated before the call.
  ///
  /// Prefer `getOrDefault(value)` for eager fallback values or
  /// `getOrHandle((left) => value)` for lazy, left-aware computation.
  ///
  /// ### Example
  /// ```dart
  /// Right<String, int>(12).getOrElse(() => 17);      // Result: 12
  /// Left<String, int>('error').getOrElse(() => 17);  // Result: 17
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
