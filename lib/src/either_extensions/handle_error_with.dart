import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';
import 'handle_error.dart';

/// Provides `handleErrorWith` for [Either].
extension HandleErrorWithEitherExtension<L, R> on Either<L, R> {
  /// Recovers from a [Left] with a function that returns another [Either].
  ///
  /// If this is a [Left], calls [f] with its value and returns the resulting
  /// [Either]. The recovery can therefore produce a [Right] or a new [Left]. If
  /// this is already a [Right], [f] is not called and the right value is
  /// preserved.
  ///
  /// Unlike [HandleErrorEitherExtension.handleError], [f] can return another
  /// [Left] instead of always recovering to a [Right].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).handleErrorWith<String>(
  ///   (value) => Right<String, int>(value + 1),
  /// ); // Result: Right(12)
  ///
  /// Left<int, int>(12).handleErrorWith<String>(
  ///   (value) => Right<String, int>(value + 1),
  /// ); // Result: Right(13)
  ///
  /// Left<int, int>(12).handleErrorWith<String>(
  ///   (value) => Left<String, int>('invalid: $value'),
  /// ); // Result: Left('invalid: 12')
  /// ```
  @covarianceSafe
  @useResult
  Either<C, R> handleErrorWith<C>(Either<C, R> Function(L value) f) =>
      switch (this) {
        Left(:final value) => f(value),
        Right(:final value) => Either<C, R>.right(value),
      };
}
