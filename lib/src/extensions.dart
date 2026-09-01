import 'dart:async';

import 'package:meta/meta.dart';

import 'dart_either.dart';

/// Provide [toEitherFuture] extension on [Future].
extension ToEitherFutureExtension<R> on Future<R> {
  /// Returns a future that wraps this future's value or non-fatal error in an
  /// [Either].
  ///
  /// If this future completes with a value, the returned future completes with
  /// a [Right] containing that value.
  /// If this future completes with a non-fatal error, [errorMapper] maps that
  /// error and the returned future completes with a [Left] containing the
  /// mapped value.
  ///
  /// If the error matches [Either.registerFatalError], it is not converted to a
  /// [Left]. The returned future completes with the original error and stack
  /// trace instead.
  ///
  /// This extension operates on a future that has already been created. Use
  /// [Either.tryCatchAsync] when invoking the operation may throw before it
  /// returns a future.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final Future<int> f = Future.value(1);
  /// final Future<Either<Object, int>> eitherFuture = f.toEitherFuture((e, s) => e);
  ///
  /// eitherFuture.then(print); // prints Either.Right(1)
  /// ```
  Future<Either<L, R>> toEitherFuture<L>(ErrorMapper<L> errorMapper) =>
      Either.tryCatchAsync(action: () => this, errorMapper: errorMapper);
}

/// Provides [thenFlatMapEither] on a [Future] of [Either].
extension AsyncFlatMapFutureExtension<L, R> on Future<Either<L, R>> {
  /// Chains the right value of the [Either] produced by this future.
  ///
  /// When this future produces a [Right], [f] receives its value. The returned
  /// [Either], whether produced immediately or asynchronously, becomes the
  /// result without introducing a nested `Either`.
  ///
  /// When this future produces a [Left], [f] is not called and that left value
  /// is forwarded unchanged. Errors from this future or [f] remain errors of
  /// the returned future; this method does not convert them to [Left] values.
  ///
  /// This is the pipeline-style `flatMap` operation for a
  /// `Future<Either<L, R>>`. In the name, `then` refers to completion of the
  /// outer future, `flatMap` describes the right-side operation, and `Either`
  /// identifies the inner type. For a direct `async`/`await` flow, use
  /// [Either.bindingAsync] and bind each `Future<Either>` to its effect.
  /// This keeps longer flows flat when later operations depend on earlier
  /// right values, instead of nesting callbacks.
  /// [Either.binding] is the synchronous counterpart.
  ///
  /// ### Example
  ///
  /// ```dart
  /// Future<Either<String, int>> loadUserId() async =>
  ///     Either<String, int>.right(1);
  ///
  /// Future<Either<String, String>> loadUserName(int id) async =>
  ///     id == 1
  ///         ? Either<String, String>.right('Petrus')
  ///         : Either<String, String>.left('User not found');
  ///
  /// Future<void> main() async {
  ///   final Either<String, String> result =
  ///       await loadUserId().thenFlatMapEither(loadUserName);
  ///   print(result); // Right('Petrus')
  /// }
  /// ```
  Future<Either<L, C>> thenFlatMapEither<C>(
          FutureOr<Either<L, C>> Function(R value) f) =>
      then(
        (either) => either.fold(
          ifLeft: (v) => v.left<C>(),
          ifRight: (v) => Future.sync(() => f(v)),
        ),
      );
}

/// Provides [thenMapEither] on a [Future] of [Either].
extension AsyncMapFutureExtension<L, R> on Future<Either<L, R>> {
  /// Transforms the right value of the [Either] produced by this future.
  ///
  /// When this future produces a [Right], [f] receives its value. The callback
  /// may return [C] immediately or asynchronously, and its result is wrapped in
  /// a new [Right].
  ///
  /// When this future produces a [Left], [f] is not called and that left value
  /// is forwarded unchanged. Errors from this future or [f] remain errors of
  /// the returned future; this method does not convert them to [Left] values.
  ///
  /// This is the pipeline-style `map` operation for a
  /// `Future<Either<L, R>>`. In the name, `then` refers to completion of the
  /// outer future, `map` describes the right-side operation, and `Either`
  /// identifies the inner type. For a direct `async`/`await` flow, use
  /// [Either.bindingAsync] and bind each `Future<Either>` to its effect.
  /// This keeps longer flows flat when later operations depend on earlier
  /// right values, instead of nesting callbacks.
  /// [Either.binding] is the synchronous counterpart.
  ///
  /// ### Example
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   final Future<Either<String, int>> count =
  ///       Future.value(Either<String, List<String>>.right(['a', 'b']))
  ///           .thenMapEither((items) => items.length);
  ///
  ///   print(await count); // Right(2)
  /// }
  /// ```
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
