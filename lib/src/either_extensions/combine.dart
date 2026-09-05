import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Provide [combine] on [Either] without crossing a covariant instance method
/// boundary.
extension CombineEitherExtension<L, R> on Either<L, R> {
  /// Combines this [Either] with [other].
  ///
  /// If both values are [Right], combines their right values using [combineRight].
  /// If both values are [Left], combines their left values using [combineLeft].
  /// Otherwise, returns the sole [Left] value.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final rr = Right<String, int>(1).combine(
  ///   Right<String, int>(2),
  ///   combineLeft: (a, b) => '$a,$b',
  ///   combineRight: (a, b) => a + b,
  /// ); // Right(3)
  ///
  /// final ll = Left<String, int>('a').combine(
  ///   Left<String, int>('b'),
  ///   combineLeft: (a, b) => '$a,$b',
  ///   combineRight: (a, b) => a + b,
  /// ); // Left('a,b')
  ///
  /// final lr = Left<String, int>('a').combine(
  ///   Right<String, int>(2),
  ///   combineLeft: (a, b) => '$a,$b',
  ///   combineRight: (a, b) => a + b,
  /// ); // Left('a')
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R> combine(
    Either<L, R> other, {
    required L Function(L left1, L left2) combineLeft,
    required R Function(R right1, R right2) combineRight,
  }) =>
      switch (this) {
        Left(value: final one) => switch (other) {
            Left(value: final two) => Either<L, R>.left(combineLeft(one, two)),
            Right() => this,
          },
        Right(value: final one) => switch (other) {
            Left() => other,
            Right(value: final two) =>
              Either<L, R>.right(combineRight(one, two)),
          },
      };
}
