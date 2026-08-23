import '../dart_either.dart';
import '../internal.dart';

/// Provides `getOrHandle` for [Either].
extension GetOrHandleEitherExtension<L, R> on Either<L, R> {
  /// Returns the [Right.value] or computes a fallback from the [Left.value].
  ///
  /// If this is a [Left], calls the fallback function [defaultValue] with its
  /// value and returns the result. If this is a [Right], [defaultValue] is not
  /// called.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).getOrHandle((value) => value + 5); // Result: 12
  /// Left<int, int>(12).getOrHandle((value) => value + 5);  // Result: 17
  /// ```
  @covarianceSafe
  R getOrHandle(R Function(L value) defaultValue) => switch (this) {
        Left(:final value) => defaultValue(value),
        Right(:final value) => value,
      };
}
