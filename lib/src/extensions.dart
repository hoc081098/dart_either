import 'dart:async';

import 'dart_either.dart';

/// Provide [toEitherStream] extension on [Stream].
extension ToEitherStreamExtension<R> on Stream<R> {
  /// Transform data events to [Right]s and error events to [Left]s.
  ///
  /// When the source stream emits a data event, the result stream will emit
  /// a [Right] wrapping that data event.
  ///
  /// When the source stream emits a error event, calling [errorMapper] with that error
  /// and the result stream will emits a [Left] wrapping the result.
  ///
  /// The done events will be forwarded.
  ///
  /// ### Example
  /// ```dart
  /// final Stream<int> s = Stream.fromIterable([1, 2, 3, 4]);
  /// final Stream<Either<Object, int>> eitherStream = s.toEitherStream((e, s) => e);
  ///
  /// eitherStream.listen(print); // prints Either.Right(1), Either.Right(2),
  ///                             // Either.Right(3), Either.Right(4),
  /// ```
  Stream<Either<L, R>> toEitherStream<L>(ErrorMapper<L> errorMapper) =>
      Either.catchStreamError<L, R>(errorMapper, this);
}

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
      Either.catchFutureError(errorMapper, () => this);
}

/// Provide [asyncFlatMap] extension on [Future] of [Either].
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
  Future<Either<L, C>> asyncFlatMap<C>(
          FutureOr<Either<L, C>> Function(R value) f) =>
      then(
        (either) => either.fold(
          ifLeft: (v) => v.left<C>(),
          ifRight: (v) => Future.sync(() => f(v)),
        ),
      );
}

/// Provide [asyncMap] extension on [Future] of [Either].
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
  Future<Either<L, C>> asyncMap<C>(FutureOr<C> Function(R value) f) => then(
        (either) => either.fold(
          ifLeft: (v) => v.left<C>(),
          ifRight: (v) => Future.sync(() => f(v)).then((v) => v.right<L>()),
        ),
      );
}

/// Provide [left] and [right] extensions on any types.
extension ToEitherObjectExtension<T> on T {
  /// Return a [Left] that contains [this] value.
  /// This is a shorthand for [Either.left].
  ///
  /// ### Example
  /// ```dart
  /// Either<int, Never> e1 = 1.left<Never>();
  /// Either<int, String> e2 = 1.left<String>();
  /// ```
  Either<T, R> left<R>() => Either<T, R>.left(this);

  /// Return a [Right] that contains [this] value.
  /// This is a shorthand for [Either.right].
  ///
  /// ### Example
  /// ```dart
  /// Either<Never, int> e1 = 1.right<Never>();
  /// Either<String, int> e2 = 1.right<String>();
  /// ```
  Either<L, T> right<L>() => Either<L, T>.right(this);
}
