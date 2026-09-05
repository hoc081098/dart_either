import '../dart_either.dart';
import '../internal.dart';

/// Adds [getOrDefault] to [Either].
extension GetOrDefaultEitherExtension<L, R> on Either<L, R> {
  /// Returns [Right.value] if this is a [Right]. Otherwise, returns
  /// [defaultValue].
  ///
  /// [defaultValue] is eager, so it is evaluated before the call.
  /// For lazy fallback computation, use `getOrHandle`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final int fromRight = Right<String, int>(12).getOrDefault(17);    // 12
  /// final int fromLeft = Left<String, int>('error').getOrDefault(17); // 17
  /// ```
  @covarianceSafe
  R getOrDefault(R defaultValue) => switch (this) {
        Left() => defaultValue,
        Right(:final value) => value,
      };
}
