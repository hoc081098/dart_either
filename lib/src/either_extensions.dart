import 'package:meta/meta.dart';

import 'dart_either.dart';
import 'internal.dart';

/// Provide [toFuture] extension on [Either].
extension AsFutureEitherExtension<L extends Object, R> on Either<L, R> {
  /// Convert this [Either] to a [Future].
  /// If [this] is [Right], the Future will complete with [Right.value] as its value.
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
  R getOrThrow() => getOrHandle((value) => throw value);
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
  @useResult
  Either<L, R> flatten() => flatMap(identity);
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
  T merge() => fold(ifLeft: identity, ifRight: identity);
}
