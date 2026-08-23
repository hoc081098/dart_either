import 'package:meta/meta.dart';

import '../dart_either.dart';
import '../internal.dart';

/// Provides `flatMap` for [Either].
extension FlatMapEitherExtension<L, R> on Either<L, R> {
  /// Chains this [Either] with another computation that returns an [Either].
  ///
  /// If this is a [Right], calls [f] with its value and returns the resulting
  /// [Either]. If this is a [Left], [f] is not called and the left value is
  /// preserved.
  ///
  /// Unlike [Either.map], [f] returns an [Either]. This allows the next
  /// computation to return either a new [Right] value or a [Left] without
  /// creating a nested `Either`.
  ///
  /// ### Example
  /// ```dart
  /// Right<String, int>(12)
  ///     .flatMap((value) => Right<String, String>('flower $value'));
  /// // Result: Right('flower 12')
  ///
  /// Right<String, int>(12)
  ///     .flatMap((value) => Left<String, String>('invalid: $value'));
  /// // Result: Left('invalid: 12')
  ///
  /// Left<String, int>('error')
  ///     .flatMap((value) => Right<String, String>('flower $value'));
  /// // Result: Left('error')
  /// ```
  @covarianceSafe
  @useResult
  Either<L, C> flatMap<C>(Either<L, C> Function(R value) f) => switch (this) {
        Left(:final value) => Either<L, C>.left(value),
        Right(:final value) => f(value),
      };
}
