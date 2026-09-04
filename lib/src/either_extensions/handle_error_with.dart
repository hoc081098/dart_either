import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Provides [handleErrorWith] on [Either] without crossing a covariant
/// instance-method boundary.
extension HandleErrorWithEitherExtension<L, R> on Either<L, R> {
  /// Handles a [Left] with [f], which returns a new [Either].
  ///
  /// - If this is a [Left], invokes [f] exactly once and returns its result
  ///   directly. The result may be either a [Left] or a [Right].
  /// - If this is a [Right], does not invoke [f] and returns an equivalent
  ///   [Right] containing the unchanged value. Because the returned [Either]
  ///   has the new left type [L2], it is not guaranteed to be identical to
  ///   this instance.
  ///
  /// This is the left-side counterpart of `flatMap`:
  /// `flatMap` lets a [Right] callback choose the next channel,
  /// while `handleErrorWith` gives that choice to a [Left] callback.
  ///
  /// In some libraries or languages, this operation is also known as
  /// `recoverWith` or `flatMapError`.
  /// Exceptions thrown by [f] are not caught.
  ///
  /// ### Example
  /// ```dart
  /// final rightSkippingRight = Right<int, int>(12).handleErrorWith(
  ///   (value) => Right<String, int>(value + 1),
  /// ); // Right(12); the callback is skipped
  ///
  /// final rightSkippingLeft = Right<int, int>(12).handleErrorWith(
  ///   (value) => Left<String, int>('error: $value'),
  /// ); // Right(12); the callback is skipped
  ///
  /// final leftToRight = Left<int, int>(12).handleErrorWith(
  ///   (value) => Right<String, int>(value + 1),
  /// ); // Right(13)
  ///
  /// final leftToLeft = Left<int, int>(12).handleErrorWith(
  ///   (value) => Left<String, int>('error: $value'),
  /// ); // Left('error: 12')
  /// ```
  @covarianceSafe
  @useResult
  Either<L2, R> handleErrorWith<L2>(Either<L2, R> Function(L value) f) =>
      switch (this) {
        Left(value: final value) => f(value),
        Right(value: final value) => Either<L2, R>.right(value),
      };
}
