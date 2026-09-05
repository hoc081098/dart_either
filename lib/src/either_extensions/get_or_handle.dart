import '../dart_either.dart';
import '../internal.dart';

/// Adds [getOrHandle] to [Either].
extension GetOrHandleEitherExtension<L, R> on Either<L, R> {
  /// Returns [Right.value] if this is a [Right]. If this is a [Left], invokes
  /// [defaultValue] with [Left.value] and returns the callback result.
  ///
  /// [defaultValue] is invoked exactly once for a [Left] and is not invoked for
  /// a [Right]. Exceptions thrown by [defaultValue] are not caught.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final int fromRight =
  ///     Right<String, int>(12).getOrHandle((error) => error.length);
  /// // 12; the callback is skipped
  ///
  /// final int fromLeft =
  ///     Left<String, int>('missing').getOrHandle((error) => error.length);
  /// // 7
  /// ```
  @covarianceSafe
  R getOrHandle(R Function(L value) defaultValue) => switch (this) {
        Left(value: final value) => defaultValue(value),
        Right(value: final value) => value,
      };
}
