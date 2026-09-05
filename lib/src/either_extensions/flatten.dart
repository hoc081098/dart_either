import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Adds [flatten] to nested [Either] values.
extension FlattenEitherExtension<L, R> on Either<L, Either<L, R>> {
  /// Flattens a nested [Either].
  ///
  /// If this is a [Right], returns [Right.value], which is the nested [Either].
  /// If this is a [Left], returns an equivalent [Left].
  ///
  /// This is equivalent to `flatMap(identity)`.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final Either<int, int> rightOfRight =
  ///     Right<int, Either<int, int>>(Right(12)).flatten();
  /// // Right(12)
  ///
  /// final Either<int, int> rightOfLeft =
  ///     Right<int, Either<int, int>>(Left(12)).flatten();
  /// // Left(12)
  ///
  /// final Either<int, int> left =
  ///     Left<int, Either<int, int>>(12).flatten();
  /// // Left(12)
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R> flatten() => switch (this) {
        Left(:final value) => Either<L, R>.left(value),
        Right(:final value) => value,
      };
}
