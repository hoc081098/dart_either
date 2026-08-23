import '../dart_either.dart';
import '../internal.dart';
import '../either_extensions.dart';

/// Provides the deprecated `getOrElse` operation for [Either].
extension GetOrElseEitherExtension<L, R> on Either<L, R> {
  /// Returns the [Right.value] or a lazily computed fallback value.
  ///
  /// If this is a [Left], calls the fallback function [defaultValue] and
  /// returns its result. If this is a [Right], [defaultValue] is not called.
  ///
  /// This method is deprecated. Use
  /// [GetOrDefaultEitherExtension.getOrDefault] for an eager fallback value, or
  /// [GetOrHandleEitherExtension.getOrHandle] for a lazy fallback that can use
  /// the [Left.value].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).getOrElse(() => 17); // Result: 12
  /// Left<int, int>(12).getOrElse(() => 17);  // Result: 17
  /// ```
  @Deprecated(
    'Use getOrDefault(value) for eager fallback, '
        'or getOrHandle for lazy fallback.',
  )
  @covarianceSafe
  R getOrElse(R Function() defaultValue) => switch (this) {
        Left() => defaultValue(),
        Right(:final value) => value,
      };
}
