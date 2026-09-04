import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

import 'binding.dart';
import 'either_extensions.dart';
import 'extensions.dart';
import 'internal.dart';
import 'to_either_stream.dart';
import 'utils/semaphore.dart';

part 'utils/par_sequence_n_executor.dart';

/// Map [error] and [stackTrace] to a [T] value.
typedef ErrorMapper<T> = T Function(Object error, StackTrace stackTrace);

/// Rethrows [error] with [stackTrace] when it is an internal control signal or
/// matches a type registered through [Either.registerFatalError].
@internal
@pragma('vm:always-consider-inlining')
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
Object throwIfFatal(Object error, StackTrace stackTrace) => switch (error) {
      ControlError() => Error.throwWithStackTrace(error, stackTrace),
      _ when Either._fatalErrorTests.values.any((test) => test(error)) =>
        Error.throwWithStackTrace(error, stackTrace),
      _ => error,
    };

@pragma('vm:always-consider-inlining')
@pragma('vm:prefer-inline')
@pragma('dart2js:tryInline')
T Function(Object?) _const<T>(T t) => (_) => t;

///
/// ### Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098).
///
/// [Either] is a type that represents either [Right] (usually represent a "desired" value)
/// or [Left] (usually represent a "undesired" value or error value).
///
/// [Elm Result](https://package.elm-lang.org/packages/elm-lang/core/5.1.1/Result).
/// [Haskell Data.Either](https://hackage.haskell.org/package/base-4.10.0.0/docs/Data-Either.html).
/// [Rust Result](https://doc.rust-lang.org/std/result/enum.Result.html).
///
/// In day-to-day programming, it is fairly common to find ourselves writing functions that can fail.
/// For instance, querying a service may result in a connection issue, or some unexpected `JSON` response.
///
/// To communicate these errors, it has become common practice to throw exceptions; however,
/// exceptions are not tracked in any way, shape, or form by the compiler. To see what
/// kind of exceptions (if any) a function may throw, we have to dig through the source code.
/// Then, to handle these exceptions, we have to make sure we catch them at the call site. This
/// all becomes even more unwieldy when we try to compose exception-throwing procedures.
///
/// ```dart
/// double throwsSomeStuff(int i) => throw UnimplementedError();
///
/// String throwsOtherThings(double d) => throw UnimplementedError();
///
/// List<int> moreThrowing(String s) => throw UnimplementedError();
///
/// List<int> magic(int i) => moreThrowing( throwsOtherThings( throwsSomeStuff(i) ) );
/// ```
///
/// Assume we happily throw exceptions in our code. Looking at the types of the functions above,
/// any could throw a number of exceptions -- we do not know. When we compose, exceptions from any of the constituent
/// functions can be thrown. Moreover, they may throw the same kind of exception
/// (e.g., `ArgumentError`) and, thus, it gets tricky tracking exactly where an exception came from.
///
/// How then do we communicate an error? By making it explicit in the data type we return.
///
/// ## Either
///
/// `Either` is used to short-circuit a computation upon the first error.
/// By convention, the right side of an `Either` is used to hold successful values.
///
/// Because `Either` is right-biased, it is possible to define a `Monad` instance for it.
/// Since we only ever want the computation to continue in the case of [Right] (as captured by the right-bias nature),
/// we fix the left type parameter and leave the right one free. So, the map and flatMap methods are right-biased.
@immutable
@sealed
sealed class Either<L, R> {
  const Either._();

  @covarianceSafe
  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  T _foldInternal<T>({
    required T Function(L value) ifLeft,
    required T Function(R value) ifRight,
  }) =>
      switch (this) {
        Left(value: final l) => ifLeft(l),
        Right(value: final r) => ifRight(r),
      };

  static final Map<Type, bool Function(Object)> _fatalErrorTests = {};

  /// Registers errors of type [T] as fatal to `Either` error capture.
  ///
  /// An error matching [T], including any subtype of [T], remains an error with
  /// its original stack trace instead of being passed to an [ErrorMapper] and
  /// converted to a [Left].
  ///
  /// This policy applies to [Either.tryCatch], [Either.tryCatchAsync],
  /// [ToEitherFutureExtension.toEitherFuture], and
  /// [ToEitherStreamExtension.toEitherStream].
  ///
  /// Each Dart isolate keeps its own registry. Registering [T] in one isolate
  /// does not affect other isolates, so each spawned isolate must register the
  /// types it needs. Registrations are additive, and registering the same type
  /// more than once has no additional effect.
  ///
  /// Internal [ControlError] values are always treated as fatal and do not need
  /// to be registered.
  ///
  /// ### Example
  ///
  /// ```dart
  /// class CancellationException implements Exception {}
  ///
  /// Either.registerFatalError<CancellationException>();
  /// ```
  static void registerFatalError<T extends Object>() =>
      _fatalErrorTests.putIfAbsent(T, () => (error) => error is T);

  // -----------------------------------------------------------------------------
  //
  // BEGIN: constructors
  //
  // -----------------------------------------------------------------------------

  /// Create a [Left].
  const factory Either.left(L left) = Left;

  /// Create a [Right].
  const factory Either.right(R right) = Right;

  /// Evaluates the specified [block] and wraps the result in a [Right].
  ///
  /// If a non-fatal error is thrown, [errorMapper] maps it and the result is
  /// wrapped in a [Left]. Errors matching [Either.registerFatalError] are
  /// rethrown with their original stack trace instead.
  ///
  /// ### Example
  /// ```dart
  /// Either<Object, int>.catchError((e, s) => e, () => throw Exception()); // Result: Left(Exception())
  /// Either<Object, String>.catchError((e, s) => e, () => 'hoc081098');    // Result: Right('hoc081098')
  /// ```
  @Deprecated('Use Either<L, R>.tryCatch() instead. It will be removed in v3.')
  factory Either.catchError(ErrorMapper<L> errorMapper, R Function() block) =>
      Either.tryCatch(action: block, errorMapper: errorMapper);

  /// Evaluates the specified [action] and wraps the result in a [Right].
  ///
  /// If a non-fatal error is thrown, [errorMapper] maps it and the result is
  /// wrapped in a [Left]. Errors matching [Either.registerFatalError] are
  /// rethrown with their original stack trace instead.
  ///
  /// ### Example
  /// ```dart
  /// Either<Object, int>.tryCatch(
  ///   action: () => throw Exception(),
  ///   errorMapper: (e, s) => e,
  /// ); // Result: Left(Exception())
  ///
  /// Either<Object, String>.tryCatch(
  ///   action: () => 'hoc081098',
  ///   errorMapper: (e, s) => e,
  /// ); // Result: Right('hoc081098')
  /// ```
  factory Either.tryCatch({
    required R Function() action,
    required ErrorMapper<L> errorMapper,
  }) {
    try {
      return Either.right(action());
    } catch (e, s) {
      return Either.left(errorMapper(throwIfFatal(e, s), s));
    }
  }

  /// [Monad comprehension](https://en.wikipedia.org/wiki/List_comprehension#Monad_comprehension).
  /// [Syntactic sugar do-notation](https://en.wikipedia.org/wiki/Monad_(functional_programming)#Syntactic_sugar_do-notation).
  /// Although using [flatMap] openly often makes sense, many programmers prefer a syntax
  /// that mimics imperative statements (called `do-notation` in `Haskell`, `perform-notation` in `OCaml`,
  /// `computation expressions` in `F#`, and `for comprehension` in `Scala`).
  /// This is only syntactic sugar that disguises a monadic pipeline as a code block.
  ///
  /// Calls [block] with a scope-bound [EitherEffect] and returns its [Either].
  ///
  /// Inside [block], `effect.bind(either)` returns the [Right.value] of
  /// `either`. Binding a [Left] immediately terminates this binding scope and
  /// returns that [Left]. [BindEitherExtension.bind] provides the equivalent
  /// `either.bind(effect)` syntax. When there is no [Right] value to extract,
  /// [RaiseEitherEffectExtension.raise] short-circuits directly with a left
  /// value without first constructing a [Left] solely to bind it.
  ///
  /// Each invocation owns a distinct scope. Nested binding scopes therefore
  /// catch only their own short-circuit. The capability is valid only while
  /// [block] is running; invoking a captured capability after [block] returns
  /// throws a [StateError]. Ordinary exceptions propagate unchanged.
  ///
  /// ### Example
  /// ```dart
  /// class ExampleError {}
  ///
  /// Either<ExampleError, int> provideX() { ... }
  /// Either<ExampleError, int> provideY() { ... }
  /// Either<ExampleError, int> provideZ(int x, int y) { ... }
  ///
  /// final result = Either<ExampleError, int>.binding((effect) {
  ///   final int x = provideX().bind(effect);
  ///   final int y = effect.bind(provideY());
  ///   final int z = provideZ(x, y).bind(effect);
  ///   return z;
  /// });
  /// ```
  ///
  /// ### NOTE
  /// - Do NOT catch [ControlError] in [block].
  /// - Do NOT store [EitherEffect] or invoke it after [block] returns.
  /// - Errors thrown by [block] are not converted to [Left].
  /// - Use [Either.tryCatch], [Either.tryCatchAsync] or [ToEitherStreamExtension.toEitherStream] to catch error,
  ///   then bind the resulting [Either].
  ///
  /// ```dart
  /// /// This function can throw an error.
  /// int canThrowAnError() { ... }
  ///
  /// // DON'T
  /// final badResult = Either<ExampleError, int>.binding((_) {
  ///   final int value = canThrowAnError();
  ///   return value;
  /// });
  ///
  /// // DO
  /// ExampleError toExampleError(Object e, StackTrace st) { ... }
  ///
  /// final result = Either<ExampleError, int>.binding((effect) {
  ///   final int value = Either<ExampleError, int>.tryCatch(
  ///     action: canThrowAnError,
  ///     errorMapper: toExampleError,
  ///   ).bind(effect);
  ///   return value;
  /// });
  /// ```
  factory Either.binding(
      @monadComprehensions R Function(EitherEffect<L> effect) block) {
    final EitherEffect<L> effect = _BindingScope<Never Function(L)>._(_Token());

    try {
      final value = block(effect);
      effect._throwIfRaised();

      return Either.right(value);
    } on ControlError<L> catch (e) {
      if (identical(effect._token, e._token)) {
        return Either.left(e._value);
      } else {
        rethrow;
      }
    } finally {
      effect._close();
    }
  }

  // -----------------------------------------------------------------------------
  //
  // END: constructors
  //
  // -----------------------------------------------------------------------------

  // -----------------------------------------------------------------------------
  //
  // BEGIN: static methods.
  //
  // -----------------------------------------------------------------------------

  /// Returns a [Right] if [value] is not `null`, otherwise a [Left] containing `null`.
  ///
  /// ### Example
  /// ```dart
  /// Either.fromNullable<String>(null);        // Result: Left(null)
  /// Either.fromNullable<String>('hoc081098'); // Result: Right('hoc081098')
  /// ```
  @useResult
  static Either<void, R> fromNullable<R extends Object>(R? value) =>
      value == null ? const Either.left(null) : Either.right(value);

  /// [Monad comprehension](https://en.wikipedia.org/wiki/List_comprehension#Monad_comprehension).
  /// [Syntactic sugar do-notation](https://en.wikipedia.org/wiki/Monad_(functional_programming)#Syntactic_sugar_do-notation).
  /// Although using [flatMap] openly often makes sense, many programmers prefer a syntax
  /// that mimics imperative statements (called `do-notation` in `Haskell`, `perform-notation` in `OCaml`,
  /// `computation expressions` in `F#`, and `for comprehension` in `Scala`).
  /// This is only syntactic sugar that disguises a monadic pipeline as a code block.
  ///
  /// Calls [block] with a scope-bound [EitherEffect] and returns its [Either]
  /// wrapped in a [Future].
  ///
  /// Inside [block], `effect.bind(either)` returns the [Right.value] of
  /// `either`. Binding a [Left] immediately terminates this binding scope and
  /// completes the returned future with that [Left]. When there is no [Right]
  /// value to extract, [RaiseEitherEffectExtension.raise] short-circuits
  /// directly with a left value without first constructing a [Left] solely to
  /// bind it.
  ///
  /// [BindFutureEitherEffectExtension.bindFuture] and
  /// [BindEitherFutureExtension.bind] unwrap an [Either] produced by a future.
  /// An error from that future propagates unchanged.
  ///
  /// Each invocation owns a distinct scope. Nested binding scopes therefore
  /// catch only their own short-circuit. The capability remains valid through
  /// the asynchronous work returned by [block], then closes when that work
  /// settles. Invoking a captured capability afterward throws a [StateError].
  ///
  /// ### Example
  /// ```dart
  /// class ExampleError {}
  ///
  /// Either<ExampleError, int> provideX() { ... }
  /// Future<Either<ExampleError, int>> provideY() { ... }
  /// Future<Either<ExampleError, int>> provideZ(int x, int y) { ... }
  ///
  /// final result = Either.bindingAsync<ExampleError, int>((effect) async {
  ///   final int x = provideX().bind(effect);
  ///   final int y = await effect.bindFuture(provideY());
  ///   final int z = await provideZ(x, y).bind(effect);
  ///   return z;
  /// });
  /// ```
  ///
  /// ### NOTE
  /// - Do NOT catch [ControlError] in [block].
  /// - Do NOT store [EitherEffect] or invoke it after the returned future settles.
  /// - Errors thrown by [block], or emitted by a bound future, are not converted to [Left].
  /// - Use [Either.tryCatch], [Either.tryCatchAsync] or [ToEitherStreamExtension.toEitherStream] to catch error,
  ///   then bind the resulting [Either].
  /// ```dart
  /// /// This function can throw an error.
  /// int canThrowAnError() { ... }
  /// Future<int> canReturnAnErrorFuture() { ... }
  /// Future<int> errorFuture = Future.error(Exception());
  ///
  /// // DON'T
  /// final badResult = Either.bindingAsync<ExampleError, int>((_) async {
  ///   final int value1 = canThrowAnError();                // DON'T
  ///   final int value2 = await canReturnAnErrorFuture();   // DON'T
  ///   final int value3 = await errorFuture;                // DON'T
  ///   return value1 + value2 + value3;
  /// });
  ///
  /// // DO
  /// ExampleError toExampleError(Object e, StackTrace st) { ... }
  ///
  /// final result = Either.bindingAsync<ExampleError, int>((effect) async {
  ///   final int value1 = Either<ExampleError, int>.tryCatch(
  ///     action: canThrowAnError,
  ///     errorMapper: toExampleError,
  ///   ).bind(effect);
  ///
  ///   final int value2 = await Either.tryCatchAsync<ExampleError, int>(
  ///     action: canReturnAnErrorFuture,
  ///     errorMapper: toExampleError,
  ///   ).bind(effect);
  ///
  ///   final int value3 = await Either.tryCatchAsync<ExampleError, int>(
  ///     action: () => errorFuture,
  ///     errorMapper: toExampleError,
  ///   ).bind(effect);
  ///
  ///   return value1 + value2 + value3;
  /// });
  /// ```
  static Future<Either<L, R>> bindingAsync<L, R>(
      @monadComprehensions FutureOr<R> Function(EitherEffect<L> effect) block) {
    final EitherEffect<L> effect = _BindingScope<Never Function(L)>._(_Token());

    return Future.sync(() => block(effect))
        .then((value) {
          effect._throwIfRaised();

          return Either<L, R>.right(value);
        })
        .onError<ControlError<L>>(
          (e, s) => Either.left(e._value),
          test: (e) => identical(effect._token, e._token),
        )
        .whenComplete(() => effect._close());
  }

  /// Runs an asynchronous binding scope using the deprecated API name.
  ///
  /// This method delegates to [Either.bindingAsync] without changing the
  /// callback timing, short-circuit behavior, exception propagation, or scope
  /// lifetime.
  ///
  /// ### Example
  /// ```dart
  /// final result = await Either.futureBinding<String, int>((effect) async {
  ///   return Future.value(Either<String, int>.right(1)).bind(effect);
  /// }); // Right(1)
  /// ```
  @Deprecated(
      'Use Either.bindingAsync<L, R>() instead. It will be removed in v3.')
  static Future<Either<L, R>> futureBinding<L, R>(
    @monadComprehensions FutureOr<R> Function(EitherEffect<L> effect) block,
  ) =>
      bindingAsync<L, R>(block);

  /// Evaluates the specified [block] and wraps the result in a [Right].
  ///
  /// If [block] throws a non-fatal error or returns a future that completes with
  /// one, [errorMapper] maps that error and the returned future completes with a
  /// [Left]. If the error matches [Either.registerFatalError], the returned
  /// future completes with the original error and stack trace instead.
  ///
  /// ### Example
  /// ```dart
  /// // Result: Left(Exception())
  /// await Either.catchFutureError<Object, String>(
  ///   (e, s) => e,
  ///   () => throw Exception(),
  /// );
  ///
  /// // Result: Left(Exception())
  /// await Either.catchFutureError<Object, String>(
  ///   (e, s) => e,
  ///   () async => throw Exception(),
  /// );
  ///
  /// // Result: Right('hoc081098')
  /// await Either.catchFutureError<Object, String>(
  ///   (e, s) => e,
  ///   () => Future.value('hoc081098'),
  /// );
  ///
  /// // Result: Right('hoc081098')
  /// await Either.catchFutureError<Object, String>(
  ///   (e, s) => e,
  ///   () async => await Future.value('hoc081098'),
  /// );
  /// ```
  @Deprecated(
      'Use Either.tryCatchAsync<L, R>() instead. It will be removed in v3.')
  static Future<Either<L, R>> catchFutureError<L, R>(
    ErrorMapper<L> errorMapper,
    FutureOr<R> Function() block,
  ) =>
      tryCatchAsync(action: block, errorMapper: errorMapper);

  /// Evaluates the specified [action] and wraps the result in a [Right].
  ///
  /// If [action] throws a non-fatal error or returns a future that completes
  /// with one, [errorMapper] maps that error and the returned future completes
  /// with a [Left]. If the error matches [Either.registerFatalError], the
  /// returned future completes with the original error and stack trace instead.
  ///
  /// ### Example
  /// ```dart
  /// // Result: Left(Exception())
  /// await Either.tryCatchAsync<Object, String>(
  ///   action: () => throw Exception(),
  ///   errorMapper: (e, s) => e,
  /// );
  ///
  /// // Result: Left(Exception())
  /// await Either.tryCatchAsync<Object, String>(
  ///   action: () async => throw Exception(),
  ///   errorMapper: (e, s) => e,
  /// );
  ///
  /// // Result: Right('hoc081098')
  /// await Either.tryCatchAsync<Object, String>(
  ///   action: () => Future.value('hoc081098'),
  ///   errorMapper: (e, s) => e,
  /// );
  ///
  /// // Result: Right('hoc081098')
  /// await Either.tryCatchAsync<Object, String>(
  ///   action: () async => await Future.value('hoc081098'),
  ///   errorMapper: (e, s) => e,
  /// );
  /// ```
  static Future<Either<L, R>> tryCatchAsync<L, R>({
    required FutureOr<R> Function() action,
    required ErrorMapper<L> errorMapper,
  }) =>
      Future.sync(action).then(Either<L, R>.right).onError<Object>(
          (e, s) => Either<L, R>.left(errorMapper(throwIfFatal(e, s), s)));

  /// Transforms data events to [Right]s and non-fatal error events to [Left]s.
  ///
  /// When the source stream emits a data event, the result stream will emit
  /// a [Right] wrapping that data event.
  ///
  /// When the source stream emits a non-fatal error event, [errorMapper] maps
  /// that error and the returned stream emits a [Left] wrapping the mapped
  /// value. If the error matches [Either.registerFatalError], the returned
  /// stream emits the original error and stack trace instead.
  ///
  /// When the source stream closes, the returned stream also closes with a done
  /// event.
  ///
  /// ### Example
  /// ```dart
  /// final Stream<int> s = Stream.fromIterable([1, 2, 3, 4]);
  /// final Stream<Either<Object, int>> eitherStream = Either.catchStreamError((e, s) => e, s);
  ///
  /// eitherStream.listen(print); // prints Either.Right(1), Either.Right(2),
  ///                             // Either.Right(3), Either.Right(4),
  /// ```
  ///
  /// ```dart
  /// final Stream<int> s = Stream.error(Exception());
  /// final Stream<Either<Object, int>> eitherStream = Either.catchStreamError((e, s) => e, s);
  ///
  /// eitherStream.listen(print); // prints Either.Left(Exception)
  /// ```
  @Deprecated(
      'Use Stream.toEitherStream extension instead. It will be removed in v3.')
  @useResult
  static Stream<Either<L, R>> catchStreamError<L, R>(
    ErrorMapper<L> errorMapper,
    Stream<R> stream,
  ) =>
      stream.toEitherStream(errorMapper);

  /// Traverses the [values] iterable and runs [mapper] on each element.
  ///
  /// If one of the [mapper] returns a [Left], then it will short-circuit the operation,
  /// and returning the first encountered [Left].
  ///
  /// Otherwise, collects all values and wrap them in a [Right].
  ///
  /// This is a shorthand for `Either.sequence<L, R>(values.map(mapper))`.
  ///
  /// ### Example
  /// ```dart
  /// // Result: Left('3')
  /// Either.traverse<int, String, int>(
  ///   [1, 2, 3, 4, 5, 6],
  ///   (int i) => i < 3 ? i.toString().right() : i.left(),
  /// );
  ///
  /// // Result: Right(BuiltList.of(['1', '2', '3', '4', '5', '6']))
  /// Either.traverse<int, String, int>(
  ///   [1, 2, 3, 4, 5, 6],
  ///   (int i) => i.toString().right(),
  /// );
  /// ```
  @useResult
  static Either<L, BuiltList<R>> traverse<L, R, T>(
    Iterable<T> values,
    Either<L, R> Function(T value) mapper,
  ) =>
      sequence<L, R>(values.map(mapper));

  /// Sequences all [Either] values.
  /// If one of them is a [Left], then it will short-circuit the operation,
  /// and returning the first encountered [Left].
  ///
  /// Otherwise, collects all values and wrap them in a [Right].
  ///
  /// ### Example
  /// ```dart
  /// // Result: Left('3')
  /// Either.sequence<int, String>([1, 2, 3, 4, 5, 6]
  ///     .map((int i) => i < 3 ? i.toString().right() : i.left()));
  ///
  /// // Result: Right(BuiltList.of(['1', '2', '3', '4', '5', '6']))
  /// Either.sequence<int, String>(
  ///     [1, 2, 3, 4, 5, 6].map((int i) => i.toString().right()));
  /// ```
  @useResult
  static Either<L, BuiltList<R>> sequence<L, R>(Iterable<Either<L, R>> values) {
    final result = ListBuilder<R>();

    for (final either in values) {
      switch (either) {
        case Left(value: final l):
          return Either<L, BuiltList<R>>.left(l);
        case Right(value: final r):
          result.add(r);
      }
    }

    return Right(result.build());
  }

  /// Maps [values] to asynchronous [Either] operations and runs them with
  /// optional concurrency control.
  ///
  /// [mapper] is called for each input value to create a zero-argument function
  /// returning `Future<Either<L, R>>`. The input is materialized before those
  /// functions start. Calling [mapper] is therefore not concurrency-limited;
  /// only the functions it returns are. If [mapper] throws while the input is
  /// being materialized, no returned function is invoked and the error is
  /// thrown synchronously.
  ///
  /// This method is equivalent to calling [parSequenceN] with
  /// `functions: values.map(mapper)` after validating [maxConcurrent].
  ///
  /// ### Parameters and concurrency
  ///
  /// - [values] supplies the input values in result order.
  /// - [mapper] converts each input value into an asynchronous [Either]
  ///   operation.
  /// - [maxConcurrent] controls how many returned functions may be running at
  ///   the same time. Use `null` for no limit or a positive integer for a
  ///   finite limit.
  ///
  /// A non-null [maxConcurrent] less than or equal to zero is invalid. This
  /// method throws an [ArgumentError] synchronously, before [values] is
  /// traversed or [mapper] is called.
  ///
  /// ### Failure selection
  ///
  /// This operation is fail-fast. Its first terminal failure is selected by
  /// completion order, not input order:
  ///
  /// - If a returned function produces a [Left] first, the returned [Future]
  ///   completes successfully with that [Left].
  /// - If a returned function throws, or its future completes with an error
  ///   first, the returned [Future] completes with that error and its original
  ///   stack trace. The error is not converted to a [Left].
  ///
  /// After the first terminal failure is selected:
  ///
  /// - Functions that already completed stay completed. Their side effects are
  ///   not rolled back, and any collected [Right] values are discarded.
  /// - Functions that were invoked but have not completed keep running. They
  ///   are not cancelled, and their later values or errors cannot replace the
  ///   selected failure.
  /// - With a positive concurrency limit, functions still waiting for a permit
  ///   are rejected without being invoked. With no limit, every function has
  ///   already been invoked by the time a failure is observed.
  ///
  /// ### When `maxConcurrent` is `null`
  ///
  /// Every returned function is invoked without waiting for a permit. Because
  /// failures are observed through future completion, all functions are invoked
  /// before any produced [Left], synchronous throw, or failed future can stop
  /// them from starting. After the returned [Future] settles, unfinished
  /// functions continue running and their outcomes are ignored.
  ///
  /// ### When `maxConcurrent` is positive
  ///
  /// At most [maxConcurrent] returned functions are running at once. Each
  /// function holds its permit until its future settles. When a function
  /// succeeds with a [Right], the next waiting function may start.
  ///
  /// Once the first [Left] or error is observed, functions still waiting for a
  /// permit are rejected without being invoked. Functions that were already
  /// invoked continue running as described above.
  ///
  /// ### Successful completion
  ///
  /// If every function produces a [Right], the returned [Right] contains all
  /// values in input order, regardless of completion order. An empty [values]
  /// iterable produces a [Right] containing an empty [BuiltList].
  ///
  /// ### Example
  /// ```dart
  /// // Fetch numbers for IDs 1,2,3 with max 2 concurrent requests
  /// final result = await Either.parTraverseN<String, int, int>(
  ///   values: [1, 2, 3],
  ///   mapper: (id) => () async => fetchNumber(id),
  ///   maxConcurrent: 2,
  /// );
  /// ```
  ///
  /// ### Returns
  /// A [Future] that either:
  ///
  /// - completes successfully with the first observed [Left];
  /// - completes successfully with a [Right] containing every result in input
  ///   order; or
  /// - completes with the first observed Dart error.
  @useResult
  static Future<Either<L, BuiltList<R>>> parTraverseN<L, R, T>({
    required Iterable<T> values,
    required Future<Either<L, R>> Function() Function(T value) mapper,
    required int? maxConcurrent,
  }) {
    if (maxConcurrent != null && maxConcurrent <= 0) {
      throw ArgumentError.value(
        maxConcurrent,
        'maxConcurrent',
        'Must be greater than 0 or null for no limit.',
      );
    }

    return parSequenceN<L, R>(
      functions: values.map(mapper),
      maxConcurrent: maxConcurrent,
    );
  }

  /// Runs asynchronous [Either] operations and collects their [Right] values,
  /// with optional concurrency control.
  ///
  /// [functions] contains zero-argument functions returning
  /// `Future<Either<L, R>>`. The iterable is materialized before any function is
  /// invoked. This lets [maxConcurrent] limit execution without creating the
  /// futures in advance. If iterating [functions] throws, no function is invoked
  /// and the error is thrown synchronously.
  ///
  /// ### Parameters and concurrency
  ///
  /// - [functions] supplies the asynchronous operations in result order.
  /// - [maxConcurrent] controls how many functions may be running at the same
  ///   time. Use `null` for no limit or a positive integer for a finite limit.
  ///
  /// A non-null [maxConcurrent] less than or equal to zero is invalid. This
  /// method throws an [ArgumentError] synchronously, before [functions] is
  /// traversed or any function is invoked.
  ///
  /// ### Failure selection
  ///
  /// This operation is fail-fast. Its first terminal failure is selected by
  /// completion order, not input order:
  ///
  /// - If a function produces a [Left] first, the returned [Future] completes
  ///   successfully with that [Left].
  /// - If a function throws, or its future completes with an error first, the
  ///   returned [Future] completes with that error and its original stack trace.
  ///   The error is not converted to a [Left].
  ///
  /// After the first terminal failure is selected:
  ///
  /// - Functions that already completed stay completed. Their side effects are
  ///   not rolled back, and any collected [Right] values are discarded.
  /// - Functions that were invoked but have not completed keep running. They
  ///   are not cancelled, and their later values or errors cannot replace the
  ///   selected failure.
  /// - With a positive concurrency limit, functions still waiting for a permit
  ///   are rejected without being invoked. With no limit, every function has
  ///   already been invoked by the time a failure is observed.
  ///
  /// ### When `maxConcurrent` is `null`
  ///
  /// Every function is invoked without waiting for a permit. Because failures
  /// are observed through future completion, all functions are invoked before
  /// any produced [Left], synchronous throw, or failed future can stop them
  /// from starting. After the returned [Future] settles, unfinished functions
  /// continue running and their outcomes are ignored.
  ///
  /// ### When `maxConcurrent` is positive
  ///
  /// At most [maxConcurrent] functions are running at once. Each function holds
  /// its permit until its future settles. When a function succeeds with a
  /// [Right], the next waiting function may start.
  ///
  /// Once the first [Left] or error is observed, functions still waiting for a
  /// permit are rejected without being invoked. Functions that were already
  /// invoked continue running as described above.
  ///
  /// ### Successful completion
  ///
  /// If every function produces a [Right], the returned [Right] contains all
  /// values in input order, regardless of completion order. An empty
  /// [functions] iterable produces a [Right] containing an empty [BuiltList].
  ///
  /// ### Example
  /// ```dart
  /// // Run up to 2 concurrent requests
  /// final result = await Either.parSequenceN<String, int>(
  ///   functions: [
  ///     () async => fetchNumber(1),
  ///     () async => fetchNumber(2),
  ///     () async => fetchNumber(3),
  ///     () async => fetchNumber(4),
  ///   ],
  ///   maxConcurrent: 2,
  /// );
  /// ```
  ///
  /// ### Returns
  /// A [Future] that either:
  ///
  /// - completes successfully with the first observed [Left];
  /// - completes successfully with a [Right] containing every result in input
  ///   order; or
  /// - completes with the first observed Dart error.
  @useResult
  static Future<Either<L, BuiltList<R>>> parSequenceN<L, R>({
    required Iterable<Future<Either<L, R>> Function()> functions,
    required int? maxConcurrent,
  }) {
    if (maxConcurrent != null && maxConcurrent <= 0) {
      throw ArgumentError.value(
        maxConcurrent,
        'maxConcurrent',
        'Must be greater than 0 or null for no limit.',
      );
    }
    return _ParSequenceNExecutor(functions, maxConcurrent).run();
  }

  // -----------------------------------------------------------------------------
  //
  // END: static methods.
  //
  // -----------------------------------------------------------------------------

  /// Returns `true` if this is a [Left], `false` otherwise.
  /// Used only for performance instead of [fold].
  @useResult
  bool get isLeft;

  /// Returns `true` if this is a [Right], `false` otherwise.
  /// Used only for performance instead of [fold].
  @useResult
  bool get isRight;

  /// Applies [ifLeft] if this is a [Left] or [ifRight] if this is a [Right].
  ///
  /// [ifLeft] is the function to apply if this is a [Left].
  /// [ifRight] is the function to apply if this is a [Right].
  ///
  /// Returns the results of applying the function.
  ///
  /// ### Example
  /// ```dart
  /// final Either<Exception, String> result = Either.right('hoc081098');
  ///
  /// // Prints operation succeeded with hoc081098
  /// result.fold(
  ///   ifLeft: (value) => print('operation failed with $value') ,
  ///   ifRight: (value) => print('operation succeeded with $value'),
  /// );
  /// ```
  @covarianceSafe
  T fold<T>({
    required T Function(L value) ifLeft,
    required T Function(R value) ifRight,
  }) =>
      _foldInternal(ifLeft: ifLeft, ifRight: ifRight);

  /// If this is a [Right], applies [ifRight] with [initial] and [Right.value].
  /// Returns [initial] otherwise.
  ///
  /// ### Example
  /// ```dart
  /// final Either<Exception, String> result = Either.right('hoc081098');
  /// final String initial = 'dart_either';
  /// String combine(String acc, String v) => '$acc $v';
  ///
  /// result.foldLeft<String>(initial, combine); // Result: 'dart_either hoc081098'
  /// ```
  @covarianceSafe
  T foldLeft<T>(T initial, T Function(T acc, R element) rightOperation) =>
      _foldInternal(
        ifLeft: _const(initial),
        ifRight: (r) => rightOperation(initial, r),
      );

  /// If this is a `Left`, then return the left value in `Right` or vice versa.
  ///
  /// ### Example
  /// ```dart
  /// Left<String, Never>('left').swap();   // Result: Right('left')
  /// Right<Never, String>('right').swap(); // Result: Left('right')
  /// ```
  @covarianceSafe
  @useResult
  Either<R, L> swap() => _foldInternal(
        ifLeft: (l) => Either.right(l),
        ifRight: (r) => Either.left(r),
      );

  /// Performs the given [action] on the encapsulated [L] if this is a [Left].
  /// Returns the original [Either] unchanged.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).onLeft((_) => print('flower')); // Result: Right(12)
  /// Left<int, int>(12).onLeft((_) => print('flower'));  // Result: prints 'flower' and returns: Left(12)
  /// ```
  @covarianceSafe
  Either<L, R> onLeft(void Function(L value) action) {
    if (this case Left(value: final value)) {
      action(value);
    }
    return this;
  }

  /// Alias of [onLeft].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).tapLeft((_) => print('flower')); // Result: Right(12)
  /// Left<int, int>(12).tapLeft((_) => print('flower'));  // Result: prints 'flower' and returns: Left(12)
  /// ```
  @Deprecated('Use onLeft instead. It will be removed in v3.')
  Either<L, R> tapLeft(void Function(L value) action) => onLeft(action);

  /// Performs the given [action] on the encapsulated [R] value if this is a [Right].
  /// Returns the original [Either] unchanged.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).onRight((_) => print('flower')); // Result: prints 'flower' and returns: Right(12)
  /// Left<int, int>(12).onRight((_) => print('flower'));  // Result: Left(12)
  /// ```
  @covarianceSafe
  Either<L, R> onRight(void Function(R value) action) {
    if (this case Right(value: final value)) {
      action(value);
    }
    return this;
  }

  /// Alias of [onRight].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).tap((_) => print('flower')); // Result: prints 'flower' and returns: Right(12)
  /// Left<int, int>(12).tap((_) => print('flower'));  // Result: Left(12)
  /// ```
  @Deprecated('Use onRight instead. It will be removed in v3.')
  Either<L, R> tap(void Function(R value) action) => onRight(action);

  /// The given function is applied if this is a `Right`.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).map((_) => 'flower'); // Result: Right('flower')
  /// Left<int, int>(12).map((_) => 'flower');  // Result: Left(12)
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R2> map<R2>(R2 Function(R value) f) => _foldInternal(
        ifLeft: (l) => Either<L, R2>.left(l),
        ifRight: (r) => Either<L, R2>.right(f(r)),
      );

  /// The given function is applied if this is a `Left`.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).mapLeft((_) => 'flower'); // Result: Right(12)
  /// Left<int, int>(12).mapLeft((_) => 'flower');  // Result: Left('flower')
  /// ```
  @covarianceSafe
  @useResult
  Either<L2, R> mapLeft<L2>(L2 Function(L value) f) => _foldInternal(
        ifLeft: (l) => Either<L2, R>.left(f(l)),
        ifRight: (r) => Either<L2, R>.right(r),
      );

  /// Map over Left and Right of this Either
  ///
  /// ### Example
  /// ```dart
  /// final Either<String, int> either = Right(1);
  ///
  /// // Result: Right('1')
  /// final Either<List<String>, String> mapped = either.bimap(
  ///   leftOperation: (String s) => s.split(''),
  ///   rightOperation: (int i) => i.toString(),
  /// );
  /// ```
  ///
  /// ```dart
  /// final Either<String, int> either = Left('hoc081098');
  ///
  /// // Result: Left(['h', 'o', 'c', '0', '8', '1', '0', '9', '8'])
  /// final Either<List<String>, String> mapped = either.bimap(
  ///   leftOperation: (String s) => s.split(''),
  ///   rightOperation: (int i) => i.toString(),
  /// );
  /// ```
  @covarianceSafe
  @useResult
  Either<L2, R2> bimap<L2, R2>({
    required L2 Function(L value) leftOperation,
    required R2 Function(R value) rightOperation,
  }) =>
      _foldInternal(
        ifLeft: (l) => Either.left(leftOperation(l)),
        ifRight: (r) => Either.right(rightOperation(r)),
      );

  /// Returns `false` if [Left] or returns the result of the application of
  /// the given [predicate] to the [Right] value.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).isRightAnd((v) => v > 10); // Result: true
  /// Right<int, int>(7).isRightAnd((v) => v > 10);  // Result: false
  ///
  /// Left<int, int>(12).isRightAnd((v) => v > 10);  // Result: false
  /// Left<int, int>(12).isRightAnd((v) => v < 10);  // Result: false
  /// ```
  @covarianceSafe
  @useResult
  bool isRightAnd(bool Function(R value) predicate) => _foldInternal(
        ifLeft: _const(false),
        ifRight: predicate,
      );

  /// Returns `false` if this is a [Right], or applies [predicate] to the
  /// [Left] value and returns its result.
  ///
  /// ### Example
  /// ```dart
  /// Left<int, int>(12).isLeftAnd((v) => v > 10);  // Result: true
  /// Left<int, int>(7).isLeftAnd((v) => v > 10);   // Result: false
  ///
  /// Right<int, int>(12).isLeftAnd((v) => v > 10); // Result: false
  /// Right<int, int>(12).isLeftAnd((v) => v < 10); // Result: false
  /// ```
  @covarianceSafe
  @useResult
  bool isLeftAnd(bool Function(L value) predicate) => _foldInternal(
        ifLeft: predicate,
        ifRight: _const(false),
      );

  /// Alias of [isRightAnd].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).exists((v) => v > 10); // Result: true
  /// Left<int, int>(12).exists((v) => v > 10);  // Result: false
  /// ```
  @Deprecated('Use isRightAnd instead. It will be removed in v3.')
  @useResult
  bool exists(bool Function(R value) predicate) => isRightAnd(predicate);

  /// Returns `true` if [Left] or returns the result of the application of
  /// the given predicate to the [Right] value.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).all((v) => v > 10); // Result: true
  /// Right<int, int>(7).all((v) => v > 10);  // Result: false
  ///
  /// Left<int, int>(12).all((v) => v > 10);  // Result: true
  /// Left<int, int>(12).all((v) => v < 10);  // Result: true
  /// ```
  @covarianceSafe
  @useResult
  bool all(bool Function(R value) predicate) => _foldInternal(
        ifLeft: _const(true),
        ifRight: predicate,
      );

  /// Returns the [Right]'s value if it exists, otherwise `null`.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).getOrNull(); // Result: 12
  /// Left<int, int>(12).getOrNull();  // Result: null
  /// ```
  @covarianceSafe
  R? getOrNull() => _foldInternal(
        ifLeft: _const(null),
        ifRight: identity,
      );

  /// Returns the [Left]'s value if it exists, otherwise `null`.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).leftOrNull(); // Result: null
  /// Left<int, int>(12).leftOrNull();  // Result: 12
  /// ```
  @covarianceSafe
  L? leftOrNull() => _foldInternal(
        ifLeft: identity,
        ifRight: _const(null),
      );

  /// Alias of [getOrNull].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).orNull(); // Result: 12
  /// Left<int, int>(12).orNull();  // Result: null
  /// ```
  @Deprecated('Use getOrNull instead. It will be removed in v3.')
  R? orNull() => getOrNull();

  /// Returns the [Right.value] matching the given [predicate],
  /// or `null` if this is a [Left] or [Right.value] does not match.
  @covarianceSafe
  R? findOrNull(bool Function(R value) predicate) => switch (this) {
        Left() => null,
        Right(value: final value) => predicate(value) ? value : null,
      };

  /// Applies [ifLeft] if this is a [Left] or [ifRight] if this is a [Right].
  /// Since Dart 3.0.0, you can use "switch expression" instead of this method.
  ///
  /// This is quite similar to [fold], but with [fold], arguments will
  /// be called with [Right.value] or [Left.value], while the arguments of [when]
  /// will be called with [Right] or [Left] itself.
  ///
  /// [ifLeft] is the function to apply if this is a [Left].
  /// [ifRight] is the function to apply if this is a [Right].
  /// Returns the results of applying the function.
  ///
  /// ### Example
  /// ```dart
  /// final Either<String, int> result = Right(1);
  ///
  /// // Prints operation succeeded with 1
  /// result.when(
  ///   ifLeft: (left) => print('operation failed with ${left.value}') ,
  ///   ifRight: (right) => print('operation succeeded with ${right.value}'),
  /// );
  /// ```
  @covarianceSafe
  T when<T>({
    required T Function(Left<L, R> left) ifLeft,
    required T Function(Right<L, R> right) ifRight,
  }) {
    final self = this;
    return switch (self) { Left() => ifLeft(self), Right() => ifRight(self) };
  }

  /// Transforms either branch into a new [Right] value.
  ///
  /// - If this is a [Left], invokes [leftOperation] exactly once.
  /// - If this is a [Right], invokes [rightOperation] exactly once.
  ///
  /// The selected callback maps its branch to an [R2], which is then wrapped in
  /// a [Right]. On normal completion, the runtime result is therefore always a
  /// [Right]. The declared return type remains `Either<L, R2>`, retaining the
  /// existing left type [L].
  ///
  /// Semantically, [redeem] can be understood as combining
  /// `map(rightOperation)` with `handleError(leftOperation)`: it maps a success
  /// or recovers an error, depending on the original channel.
  /// Exceptions thrown by the selected callback are not caught.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final Either<String, int> recovered = Left<String, int>('missing').redeem(
  ///   leftOperation: (error) => error.length,
  ///   rightOperation: (value) => value * 2,
  /// );
  /// // recovered: Either.Right(7)
  ///
  /// final Either<String, int> mapped = Right<String, int>(21).redeem(
  ///   leftOperation: (error) => error.length,
  ///   rightOperation: (value) => value * 2,
  /// );
  /// // mapped: Either.Right(42)
  /// ```
  @covarianceSafe
  @useResult
  Either<L, R2> redeem<R2>({
    required R2 Function(L value) leftOperation,
    required R2 Function(R value) rightOperation,
  }) =>
      _foldInternal(ifLeft: leftOperation, ifRight: rightOperation).right<L>();

  /// Transforms either branch with an operation that returns a new [Either].
  ///
  /// - If this is a [Left], invokes [leftOperation] exactly once.
  /// - If this is a [Right], invokes [rightOperation] exactly once.
  ///
  /// The selected callback's `Either<L2, R2>` is returned directly, so it may
  /// choose either the new [Left] channel or the new [Right] channel.
  ///
  /// Semantically, [redeemWith] combines the right-side role of [flatMap] with
  /// the left-side role of [handleErrorWith]. This is not a literal sequential
  /// call to those methods: exactly one callback runs, and a [Left] returned by
  /// either callback is not processed again.
  ///
  /// Operationally, it is equivalent to
  /// `fold(ifLeft: leftOperation, ifRight: rightOperation)`.
  /// Exceptions thrown by the selected callback are not caught.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final Either<bool, String> recovered =
  ///     Left<String, int>('missing').redeemWith(
  ///   leftOperation: (error) => Right<bool, String>(error.toUpperCase()),
  ///   rightOperation: (value) => Left<bool, String>(value.isEven),
  /// );
  /// // recovered: Either.Right(MISSING)
  ///
  /// final Either<bool, String> remapped =
  ///     Right<String, int>(21).redeemWith(
  ///   leftOperation: (error) => Right<bool, String>(error.toUpperCase()),
  ///   rightOperation: (value) => Left<bool, String>(value.isEven),
  /// );
  /// // remapped: Either.Left(false)
  /// ```
  @covarianceSafe
  @useResult
  Either<L2, R2> redeemWith<L2, R2>({
    required Either<L2, R2> Function(L value) leftOperation,
    required Either<L2, R2> Function(R value) rightOperation,
  }) =>
      _foldInternal(
        ifLeft: leftOperation,
        ifRight: rightOperation,
      );
}

/// The left side of the disjoint union, as opposed to the [Right] side.
@sealed
class Left<L, R> extends Either<L, R> {
  /// The value inside [Left].
  final L value;

  /// Construct a [Left] with [value].
  const Left(this.value) : super._();

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Left && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Either.Left($value)';
}

/// The right side of the disjoint union, as opposed to the [Left] side.
@sealed
class Right<L, R> extends Either<L, R> {
  /// The value inside [Right].
  final R value;

  /// Construct a [Right] with [value].
  const Right(this.value) : super._();

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Right && value == other.value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Either.Right($value)';
}

// -----------------------------------------------------------------------------
//
// Binding
//
// -----------------------------------------------------------------------------

/// Package-internal marker for APIs that participate in monad comprehensions.
///
/// Monad comprehensions is the name for a programming idiom available
/// in multiple languages like `JavaScript`, `F#`, `Scala`, or `Haskell`.
/// The purpose of monad comprehensions is to compose sequential chains
/// of actions in a style that feels natural for programmers of all backgrounds.
/// They’re similar to `coroutines` or `async`/`await`, but extensible to existing and new types!
@internal
const monadComprehensions = _MonadComprehensions();

@Target({TargetKind.method, TargetKind.parameter, TargetKind.typedefType})
final class _MonadComprehensions {
  const _MonadComprehensions();
}

/// A scope-bound capability for binding [Either] values with the same [L].
///
/// [BindEitherEffectExtension.bind] returns an [Either]'s [Right.value].
/// Binding a [Left] short-circuits the surrounding [Either.binding] or
/// [Either.bindingAsync] scope with that left value.
/// [RaiseEitherEffectExtension.raise] is the convenience syntax for
/// short-circuiting with a left value when there is no [Right] to extract, so
/// callers do not need to construct a [Left] solely to bind it.
///
/// Obtain a library-managed capability from the binding callback. A capability
/// supplied by [Either.binding] or [Either.bindingAsync] is valid only for
/// that callback's lifetime, including asynchronous work returned by
/// [Either.bindingAsync]. Invoking it after its scope has completed throws a
/// [StateError].
///
/// Construction and binding behavior are owned by this library. Code outside
/// the library cannot instantiate, extend, implement, or replace the binding
/// behavior of an `EitherEffect`. Assigning the capability to another variable
/// aliases the same binding scope; it does not create an independent effect.
///
/// `EitherEffect` is contravariant in [L]: an effect accepting `num` errors can
/// be used where one accepting only `int` errors is required, while the unsafe
/// opposite assignment is rejected at compile time.
///
/// ### Example
/// ```dart
/// final result = Either<String, int>.binding((effect) {
///   final int value = effect.bind(Either<String, int>.right(1));
///   return value + 1;
/// }); // Right(2)
/// ```
@monadComprehensions
typedef EitherEffect<L> = _BindingScope<Never Function(L)>;

/// Internal control-flow signal raised when [EitherEffect] short-circuits by
/// binding a [Left] or calling [RaiseEitherEffectExtension.raise].
///
/// [Either.binding] and [Either.bindingAsync] catch only signals belonging to
/// their own scope. User code must not catch this error. If a block swallows
/// its scope's signal and then completes normally, the binding scope fails with
/// a [StateError].
///
/// Cannot implement or extend this class.
final class ControlError<T> extends Error {
  final _Token _token;

  /// The value inside [Left].
  final T _value;

  ControlError._(this._value, this._token);

  @override
  String toString() => 'ControlError($_value, $_token)';
}

/// Class that represents a unique token by hash comparison.
class _Token {
  @override
  String toString() => 'Token(${hashCode.toRadixString(16)})';
}

enum _BindingPhase {
  active,
  raised,
  closed,
}

/// Private binding scope with a covariant phantom [AcceptsLeft] marker.
///
/// `EitherEffect<L>` supplies `Never Function(L)` as the marker. Because a
/// function is contravariant in its parameter, composing that marker with this
/// class's covariant type parameter makes `EitherEffect` contravariant in `L`.
///
/// This class must remain final and library-private. Its constructor must
/// remain named and private because a public typedef forwards an unnamed
/// constructor from its aliased class.
final class _BindingScope<AcceptsLeft extends Function> {
  final _Token _token;
  var _phase = _BindingPhase.active;

  _BindingScope._(this._token);

  void _close() {
    _phase = _BindingPhase.closed;
  }

  void _throwIfRaised() {
    if (_phase == _BindingPhase.raised) {
      throw StateError('Binding short-circuit was intercepted.');
    }
  }

  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _ensureActive() {
    if (_phase != _BindingPhase.active) {
      throw StateError('EitherEffect was used outside its binding scope.');
    }
  }

  @monadComprehensions
  R _bind<L, R>(Either<L, R> either) {
    _ensureActive();

    switch (either) {
      case Left(value: final value):
        _phase = _BindingPhase.raised;
        throw ControlError<L>._(value, _token);
      case Right(value: final value):
        return value;
    }
  }

  @monadComprehensions
  Never _raise<L>(L value) {
    _ensureActive();

    _phase = _BindingPhase.raised;
    throw ControlError<L>._(value, _token);
  }
}

/// Provides binding syntax on a scope-bound [EitherEffect].
extension BindEitherEffectExtension<L> on EitherEffect<L> {
  /// Returns [either]'s [Right.value].
  ///
  /// A [Left] short-circuits the [Either.binding] or [Either.bindingAsync]
  /// scope that owns this effect.
  ///
  /// See [Either.binding] and [Either.bindingAsync].
  ///
  /// ### Example
  /// ```dart
  /// final result = Either<String, int>.binding((effect) {
  ///   final int value = effect.bind(Either<String, int>.right(1));
  ///   return value + 1;
  /// }); // Right(2)
  /// ```
  @monadComprehensions
  R bind<R>(Either<L, R> either) => _bind<L, R>(either);
}

/// Provides convenience raise syntax on a scope-bound [EitherEffect].
extension RaiseEitherEffectExtension<L> on EitherEffect<L> {
  /// Short-circuits the [Either.binding] or [Either.bindingAsync] scope that
  /// owns this effect with [value] as its [Left].
  ///
  /// This is convenience syntax for the case where the caller already has a
  /// left value and would otherwise construct a [Left] solely to call
  /// [BindEitherEffectExtension.bind]. For example, `effect.raise('error')`
  /// has the same short-circuit result as
  /// `effect.bind(Either<String, Never>.left('error'))` without creating the
  /// intermediate [Left]. Its [Never] return type allows use in expressions.
  ///
  /// See [Either.binding] and [Either.bindingAsync].
  ///
  /// ### Example
  /// ```dart
  /// final result = Either<String, int>.binding((effect) {
  ///   final int? value = null;
  ///   return value ?? effect.raise('missing value');
  /// }); // Left('missing value')
  /// ```
  @monadComprehensions
  Never raise(L value) => _raise(value);
}
