import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Provides [handleError] on [Either] without crossing a covariant
/// instance-method boundary.
extension HandleErrorEitherExtension<L, R> on Either<L, R> {
  /// Recovers from a [Left] by mapping its value to a [Right] value.
  ///
  /// If this is a [Left], [f] is invoked exactly once and its result is wrapped
  /// in a [Right]. If this is a [Right], [f] is not invoked and this instance is
  /// returned unchanged. Exceptions thrown by [f] are not caught.
  ///
  /// On normal completion, both paths therefore produce a [Right], although
  /// the declared return type remains `Either<L, R>`.
  ///
  /// ### Example
  /// ```dart
  /// final recovered =
  ///     Left<String, int>('missing').handleError((error) => error.length);
  /// // recovered: Either.Right(7)
  ///
  /// final sameRight =
  ///     Right<String, int>(21).handleError((error) => error.length);
  /// // sameRight: Either.Right(21)
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R> handleError(R Function(L value) f) => switch (this) {
        Left(value: final value) => Either<L, R>.right(f(value)),
        Right() => this,
      };
}
