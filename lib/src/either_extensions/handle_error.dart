import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Provides `handleError` for [Either].
extension HandleErrorEitherExtension<L, R> on Either<L, R> {
  /// Recovers from a [Left] by transforming its value into a [Right] value.
  ///
  /// If this is a [Left], calls [f] with its value and returns the result
  /// wrapped in a [Right]. If this is already a [Right], [f] is not called and
  /// the right value is preserved.
  ///
  /// ### Example
  /// ```dart
  /// Right<String, int>(12).handleError((error) => error.length);
  /// // Result: Right(12)
  ///
  /// Left<String, int>('oops').handleError((error) => error.length);
  /// // Result: Right(4)
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R> handleError(R Function(L value) f) => switch (this) {
        Left(:final value) => Right<L, R>(f(value)),
        Right(:final value) => Right<L, R>(value),
      };
}
