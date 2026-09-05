import '../dart_either.dart';
import '../internal.dart';

/// Provide [getOrDefault] on [Either] without crossing a covariant instance
/// method boundary.
extension GetOrDefaultEitherExtension<L, R> on Either<L, R> {
  /// Returns the value from this [Right] or [defaultValue] if this is a [Left].
  ///
  /// [defaultValue] is eager, so it is evaluated before the call.
  /// For lazy fallback computation, use `getOrHandle`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// Right<String, int>(12).getOrDefault(17);      // Result: 12
  /// Left<String, int>('error').getOrDefault(17);  // Result: 17
  /// ```
  @covarianceSafe
  R getOrDefault(R defaultValue) => switch (this) {
        Left() => defaultValue,
        Right(:final value) => value,
      };
}
