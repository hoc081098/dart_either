import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Provides [handleErrorWith] on [Either] without crossing a covariant
/// instance-method boundary.
extension HandleErrorWithEitherExtension<L, R> on Either<L, R> {
  /// Handles a [Left] with [f], which returns a new [Either].
  ///
  /// If this is a [Left], [f] is invoked exactly once and its result is returned
  /// directly. If this is a [Right], [f] is not invoked and an equivalent
  /// [Right] containing the unchanged value is returned. Because the returned
  /// [Either] has the new left type [L2], instance identity is not promised.
  /// Exceptions thrown by [f] are not caught.
  ///
  /// This is the left-side counterpart of
  /// [FlatMapEitherExtension.flatMap]: `flatMap` lets a [Right] callback choose
  /// the next channel, while `handleErrorWith` gives that choice to a [Left]
  /// callback.
  ///
  /// ### Example
  /// ```dart
  /// Left<int, int>(12).handleErrorWith(
  ///   (v) => Right<String, int>(v + 1),
  /// ); // Result: Right(13)
  ///
  /// Left<int, int>(12).handleErrorWith(
  ///   (v) => Left<String, int>('error: $v'),
  /// ); // Result: Left('error: 12')
  /// ```
  @covarianceSafe
  @useResult
  Either<L2, R> handleErrorWith<L2>(Either<L2, R> Function(L value) f) =>
      switch (this) {
        Left(value: final value) => f(value),
        Right(value: final value) => Either<L2, R>.right(value),
      };
}
