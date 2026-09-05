import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Adds [flatMap] to [Either].
extension FlatMapEitherExtension<L, R> on Either<L, R> {
  /// Chains an [Either]-producing computation using the [Right] value.
  ///
  /// If this is a [Right], invokes [f] exactly once with [Right.value] and
  /// returns the result. If this is a [Left], skips [f] and returns an
  /// equivalent [Left].
  ///
  /// Unlike [Either.map], [f] returns an [Either] and can therefore produce
  /// either a [Left] or a [Right]. Exceptions thrown by [f] are not caught.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final Either<String, int> rightToRight =
  ///     Right<String, int>(1).flatMap((value) => Right(value + 1));
  /// // Right(2)
  ///
  /// final Either<String, int> rightToLeft =
  ///     Right<String, int>(1).flatMap((_) => Left('error'));
  /// // Left('error')
  ///
  /// // For either Left input, the callback is not invoked.
  /// final Either<String, int> leftSkippingRight =
  ///     Left<String, int>('error').flatMap((value) => Right(value + 1));
  /// // Left('error')
  ///
  /// final Either<String, int> leftSkippingLeft =
  ///     Left<String, int>('error').flatMap((_) => Left('new error'));
  /// // Left('error')
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R2> flatMap<R2>(Either<L, R2> Function(R value) f) =>
      switch (this) {
        Left(value: final value) => Either<L, R2>.left(value),
        Right(value: final value) => f(value),
      };
}
