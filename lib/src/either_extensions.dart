import 'package:meta/meta.dart';

import 'dart_either.dart';
import 'internal.dart';

export 'either_extensions/flat_map.dart';
export 'either_extensions/get_or_else.dart';
export 'either_extensions/get_or_handle.dart';
export 'either_extensions/handle_error.dart';
export 'either_extensions/handle_error_with.dart';

/// Provide [toFuture] extension on [Either].
extension AsFutureEitherExtension<L extends Object, R> on Either<L, R> {
  /// Convert this [Either] to a [Future].
  /// If `this` is [Right], the Future will complete with [Right.value] as its value.
  /// Otherwise, the result Future will complete with [Left.value] as its error.
  Future<R> toFuture() => fold(
        ifLeft: (e) => Future.error(e),
        ifRight: (v) => Future.value(v),
      );
}

/// Provide [getOrThrow] extension on [Either].
extension GetOrThrowEitherExtension<L extends Object, R> on Either<L, R> {
  /// Returns the [Right.value] if this [Either] is [Right], otherwise throws the [Left.value].
  /// This is functionally equivalent to `getOrHandle((value) => throw value)`.
  R getOrThrow() => switch (this) {
        Left(:final value) => throw value,
        Right(:final value) => value,
      };
}

/// Provide [getOrDefault] on [Either] without crossing a covariant instance
/// method boundary.
extension GetOrDefaultEitherExtension<L, R> on Either<L, R> {
  /// Returns the value from this [Right] or [defaultValue] if this is a [Left].
  ///
  /// [defaultValue] is eager, so it is evaluated before the call.
  /// For lazy fallback computation, use
  /// [GetOrHandleEitherExtension.getOrHandle].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).getOrDefault(17); // Result: 12
  /// Left<int, int>(12).getOrDefault(17);  // Result: 17
  /// ```
  @covarianceSafe
  R getOrDefault(R defaultValue) => switch (this) {
        Left() => defaultValue,
        Right(:final value) => value,
      };
}

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

/// Provide [flatten] extension on nested [Either].
extension FlattenEitherExtension<L, R> on Either<L, Either<L, R>> {
  /// Flattens a nested [Either].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, Either<int, int>>(Right(12)).flatten(); // Result: Right(12)
  /// Right<int, Either<int, int>>(Left(12)).flatten();  // Result: Left(12)
  /// Left<int, Either<int, int>>(12).flatten();         // Result: Left(12)
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R> flatten() => switch (this) {
        Left(:final value) => Either<L, R>.left(value),
        Right(:final value) => value,
      };
}

/// Provide [merge] extension when both sides have the same type.
extension MergeEitherExtension<T> on Either<T, T> {
  /// Returns the value from [Left] or [Right].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).merge(); // Result: 12
  /// Left<int, int>(12).merge();  // Result: 12
  /// ```
  @covarianceSafe
  T merge() => fold(ifLeft: identity, ifRight: identity);
}
