import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Provides [flatMap] on [Either] without crossing a covariant instance-method
/// boundary.
extension FlatMapEitherExtension<L, R> on Either<L, R> {
  /// Binds the given function across [Right].
  ///
  /// If this is a [Right], returns the result of applying [f] to this
  /// [Right.value]. Otherwise, returns an equivalent [Left].
  ///
  /// Slightly different from [Either.map] in that [f] is expected to return an
  /// [Either], which may be a [Left]. Exceptions thrown by [f] are not caught.
  ///
  /// ### Example
  /// ```dart
  /// final rightToRight = Right<String, int>(12).flatMap(
  ///   (value) => Right<String, String>('flower $value'),
  /// ); // Right('flower 12')
  ///
  /// final rightToLeft = Right<String, int>(12).flatMap(
  ///   (value) => Left<String, String>('invalid: $value'),
  /// ); // Left('invalid: 12')
  ///
  /// // For either Left input, the callback is not invoked.
  /// final leftSkippingRight = Left<String, int>('missing').flatMap(
  ///   (value) => Right<String, String>('flower $value'),
  /// ); // Left('missing')
  ///
  /// final leftSkippingLeft = Left<String, int>('missing').flatMap(
  ///   (value) => Left<String, String>('invalid: $value'),
  /// ); // Left('missing')
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R2> flatMap<R2>(Either<L, R2> Function(R value) f) =>
      switch (this) {
        Left(value: final value) => Either<L, R2>.left(value),
        Right(value: final value) => f(value),
      };
}
