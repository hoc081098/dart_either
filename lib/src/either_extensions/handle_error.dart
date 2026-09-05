import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Provides [handleError] on [Either] without crossing a covariant
/// instance-method boundary.
extension HandleErrorEitherExtension<L, R> on Either<L, R> {
  /// Recovers from a [Left] by mapping its value to a [Right] value.
  ///
  /// - If this is a [Left], invokes [f] exactly once and wraps its result in a
  ///   [Right].
  /// - If this is a [Right], does not invoke [f] and returns this instance.
  ///
  /// On normal completion, both paths therefore produce a [Right], although
  /// the declared return type remains `Either<L, R>`.
  ///
  /// Ignoring [Right] instance identity, this can be understood as the
  /// semantics of `handleErrorWith<L>((value) => f(value).right<L>())`.
  ///
  /// In some libraries or languages, this operation is also known as
  /// `recover`. Exceptions thrown by [f] are not caught.
  ///
  /// ### Example
  /// ```dart
  /// final recovered = Left<String, int>('missing').handleError(
  ///   (error) => error.length,
  /// ); // Right(7)
  ///
  /// final right = Right<String, int>(21);
  /// final sameRight = right.handleError(
  ///   (error) => error.length,
  /// ); // Right(21); the callback is skipped
  ///
  /// identical(sameRight, right); // true
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R> handleError(R Function(L value) f) => switch (this) {
        Left(value: final value) => Either<L, R>.right(f(value)),
        Right() => this,
      };
}
