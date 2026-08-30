import 'dart:async';

import 'package:meta/meta.dart';

import 'dart_either.dart';

/// Provide [toEitherFuture] extension on [Future].
extension ToEitherFutureExtension<R> on Future<R> {
  /// Transform data value to [Right] or error value to [Left].
  /// If this Future completes with a value, returns a [Right] containing that value.
  /// Otherwise, calling [errorMapper] with the error value and wrap the result in a [Left].
  ///
  /// ### Example
  /// ```dart
  /// final Future<int> f = Future.value(1);
  /// final Future<Either<Object, int>> eitherFuture = f.toEitherFuture((e, s) => e);
  ///
  /// eitherFuture.then(print); // prints Either.Right(1)
  /// ```
  Future<Either<L, R>> toEitherFuture<L>(ErrorMapper<L> errorMapper) =>
      // ignore: deprecated_member_use_from_same_package
      Either.catchFutureError(errorMapper, () => this);
}

/// Provide [thenFlatMapEither] extension on [Future] of [Either].
extension AsyncFlatMapFutureExtension<L, R> on Future<Either<L, R>> {
  /// `flatMap` the [Either] in the [Future] context.
  ///
  /// When this [Future] completes with a [Right] value,
  /// calling [f] callback with [Right.value].
  /// And returns a new [Future] which is completed with the result of the call to [f].
  ///
  /// If this [Future] completes with a [Left] value,
  /// returns a [Future] that completes with a [Left] which containing original [Left.value].
  ///
  /// This function does not handle any errors. See [Future.then].
  Future<Either<L, C>> thenFlatMapEither<C>(
          FutureOr<Either<L, C>> Function(R value) f) =>
      then(
        (either) => either.fold(
          ifLeft: (v) => v.left<C>(),
          ifRight: (v) => Future.sync(() => f(v)),
        ),
      );
}

/// Provide [thenMapEither] extension on [Future] of [Either].
extension AsyncMapFutureExtension<L, R> on Future<Either<L, R>> {
  /// `map` the [Either] in the [Future] context.
  ///
  /// When this [Future] completes with a [Right] value,
  /// calling [f] callback with [Right.value].
  /// And returns a new [Future] which is completed with a [Right] value
  /// which containing the result of the call to [f].
  ///
  /// If this [Future] completes with a [Left] value,
  /// returns a [Future] that completes with a [Left] which containing original [Left.value].
  ///
  /// This function does not handle any errors. See [Future.then].
  Future<Either<L, C>> thenMapEither<C>(FutureOr<C> Function(R value) f) =>
      then(
        (either) => either.fold(
          ifLeft: (v) => v.left<C>(),
          ifRight: (v) => Future.sync(() => f(v)).then((v) => v.right<L>()),
        ),
      );
}

/// Provide [left] and [right] extensions on any types.
extension ToEitherObjectExtension<T> on T {
  /// Returns a [Left] containing `this`.
  /// This is a shorthand for [Either.left].
  ///
  /// ### Example
  /// ```dart
  /// Either<int, Never> e1 = 1.left<Never>();
  /// Either<int, String> e2 = 1.left<String>();
  /// ```
  @useResult
  Either<T, R> left<R>() => Either<T, R>.left(this);

  /// Returns a [Right] containing `this`.
  /// This is a shorthand for [Either.right].
  ///
  /// ### Example
  /// ```dart
  /// Either<Never, int> e1 = 1.right<Never>();
  /// Either<String, int> e2 = 1.right<String>();
  /// ```
  @useResult
  Either<L, T> right<L>() => Either<L, T>.right(this);
}
