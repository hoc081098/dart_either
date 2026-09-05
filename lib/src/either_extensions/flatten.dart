import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Provide [flatten] extension on nested [Either].
extension FlattenEitherExtension<L, R> on Either<L, Either<L, R>> {
  /// Flattens a nested [Either].
  ///
  /// If this is a [Right], return the [Right.value],
  /// Otherwise, return an equivalent [Left].
  ///
  /// This is equivalent to `flatMap(identity)`.
  ///
  /// ### Example
  /// ```dart
  /// final rightOfRight = Right<int, Either<int, int>>(Right(12)).flatten(); // Result: Right(12)
  /// final rightOfLeft = Right<int, Either<int, int>>(Left(12)).flatten();   // Result: Left(12)
  /// final left = Left<int, Either<int, int>>(12).flatten();                 // Result: Left(12)
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R> flatten() => switch (this) {
        Left(:final value) => Either<L, R>.left(value),
        Right(:final value) => value,
      };
}
