import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

import 'binding.dart';
import 'either_extensions.dart';
import 'extensions.dart';
import 'internal.dart';
import 'utils/semaphore.dart';

/// Map [error] and [stackTrace] to a [T] value.
typedef ErrorMapper<T> = T Function(Object error, StackTrace stackTrace);

extension on Object {
  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Object throwIfFatal() {
    if (this is ControlError) {
      throw this;
    }
    return this;
  }
}

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
  C _foldInternal<C>({
    required C Function(L value) ifLeft,
    required C Function(R value) ifRight,
  }) =>
      switch (this) {
        Left(value: final l) => ifLeft(l),
        Right(value: final r) => ifRight(r),
      };

  // -----------------------------------------------------------------------------
  //
  // BEGIN: constructors
  //
  // -----------------------------------------------------------------------------

  /// Create a [Left].
  const factory Either.left(L left) = Left;

  /// Create a [Right].
  const factory Either.right(R right) = Right;

  /// Evaluates the specified [block] and wrap the result in a [Right].
  ///
  /// If an error is thrown, calling [errorMapper] with that error and wrap the result in a [Left].
  ///
  /// ### Example
  /// ```dart
  /// Either<Object, int>.catchError((e, s) => e, () => throw Exception()); // Result: Left(Exception())
  /// Either<Object, String>.catchError((e, s) => e, () => 'hoc081098');    // Result: Right('hoc081098')
  /// ```
  factory Either.catchError(ErrorMapper<L> errorMapper, R Function() block) {
    try {
      return Either.right(block());
    } catch (e, s) {
      return Either.left(errorMapper(e.throwIfFatal(), s));
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
  /// `either.bind(effect)` syntax.
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
  /// - Use [Either.catchError], [Either.catchFutureError] or [Either.catchStreamError] to catch error,
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
  ///   final int value = Either<ExampleError, int>.catchError(
  ///     toExampleError,
  ///     canThrowAnError,
  ///   ).bind(effect);
  ///   return value;
  /// });
  /// ```
  factory Either.binding(
      @monadComprehensions R Function(EitherEffect<L> effect) block) {
    final scope = _BindingScope<L>(_Token());
    final eitherEffect = scope.openEitherEffect();

    try {
      final value = block(eitherEffect);
      scope.throwIfRaised();

      return Either.right(value);
    } on ControlError<L> catch (e) {
      if (identical(scope._token, e._token)) {
        return Either.left(e._value);
      } else {
        rethrow;
      }
    } finally {
      scope.close();
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
  /// completes the returned future with that [Left].
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
  /// final result = Either.futureBinding<ExampleError, int>((effect) async {
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
  /// - Use [Either.catchError], [Either.catchFutureError] or [Either.catchStreamError] to catch error,
  ///   then bind the resulting [Either].
  ///
  /// ```dart
  /// /// This function can throw an error.
  /// int canThrowAnError() { ... }
  /// Future<int> canReturnAnErrorFuture() { ... }
  /// Future<int> errorFuture = Future.error(Exception());
  ///
  /// // DON'T
  /// final badResult = Either.futureBinding<ExampleError, int>((_) async {
  ///   final int value1 = canThrowAnError();                // DON'T
  ///   final int value2 = await canReturnAnErrorFuture();   // DON'T
  ///   final int value3 = await errorFuture;                // DON'T
  ///   return value1 + value2 + value3;
  /// });
  ///
  /// // DO
  /// ExampleError toExampleError(Object e, StackTrace st) { ... }
  ///
  /// final result = Either.futureBinding<ExampleError, int>((effect) async {
  ///   final int value1 = Either<ExampleError, int>.catchError(
  ///     toExampleError,
  ///     canThrowAnError,
  ///   ).bind(effect);
  ///
  ///   final int value2 = await Either.catchFutureError<ExampleError, int>(
  ///     toExampleError,
  ///     canReturnAnErrorFuture,
  ///   ).bind(effect);
  ///
  ///   final int value3 = await Either.catchFutureError<ExampleError, int>(
  ///     toExampleError,
  ///     () => errorFuture,
  ///   ).bind(effect);
  ///
  ///   return value1 + value2 + value3;
  /// });
  /// ```
  static Future<Either<L, R>> futureBinding<L, R>(
      @monadComprehensions FutureOr<R> Function(EitherEffect<L> effect) block) {
    final scope = _BindingScope<L>(_Token());
    final eitherEffect = scope.openEitherEffect();

    return Future.sync(() => block(eitherEffect))
        .then((value) {
          scope.throwIfRaised();

          return Either<L, R>.right(value);
        })
        .onError<ControlError<L>>(
          (e, s) => Either.left(e._value),
          test: (e) => identical(scope._token, e._token),
        )
        .whenComplete(() => scope.close());
  }

  /// Evaluates the specified [block] and wrap the result in a [Right].
  ///
  /// If an error is thrown or [block] returns a future that completes with an error,
  /// calling [errorMapper] with that error and wrap the result in a [Left].
  ///
  /// ### Example
  /// ```dart
  /// // Result: Left(Exception())
  /// await Either.catchFutureError<Object, String>(
  ///   (e, s) => e,
  ///   () => throw Exception())
  /// );
  ///
  /// // Result: Left(Exception())
  /// await Either.catchFutureError<Object, String>(
  ///   (e, s) => e,
  ///   () async => throw Exception())
  /// );
  ///
  /// // Result: Right('hoc081098')
  /// await Either.catchFutureError<Object, String>(
  ///   (e, s) => e,
  ///   () => Future.value('hoc081098'))
  /// );
  ///
  /// // Result: Right('hoc081098')
  /// await Either.catchFutureError<Object, String>(
  ///   (e, s) => e,
  ///   () async => await Future.value('hoc081098'))
  /// );
  /// ```
  static Future<Either<L, R>> catchFutureError<L, R>(
    ErrorMapper<L> errorMapper,
    FutureOr<R> Function() block,
  ) =>
      Future.sync(block)
          .then((value) => Either<L, R>.right(value))
          .onError<Object>(
              (e, s) => Either.left(errorMapper(e.throwIfFatal(), s)));

  /// Transforms data events to [Right]s and error events to [Left]s.
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
  @useResult
  static Stream<Either<L, R>> catchStreamError<L, R>(
    ErrorMapper<L> errorMapper,
    Stream<R> stream,
  ) =>
      stream.transform(
        StreamTransformer<R, Either<L, R>>.fromHandlers(
          handleData: (data, sink) => sink.add(Either.right(data)),
          handleError: (e, s, sink) =>
              sink.add(Either.left(errorMapper(e.throwIfFatal(), s))),
        ),
      );

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

  /// Traverses the [values] iterable and runs [mapper] on each element with concurrency control.
  ///
  /// For each value in [values], applies [mapper] to get a function that returns `Future<Either<L, R>>`,
  /// then runs these functions in parallel with concurrency limit [maxConcurrent].
  ///
  /// If [maxConcurrent] is `null`, all functions run concurrently without limit.
  /// If any function returns a [Left], the operation short-circuits and returns that [Left].
  /// Otherwise, collects all [Right] values into a [BuiltList].
  ///
  /// This is a shorthand for `Either.parSequenceN<L, R>(functions: values.map(mapper), maxConcurrent: maxConcurrent)`.
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
  /// ### Parameters
  /// - [values]: The values to traverse.
  /// - [mapper]: Function that takes a value and returns a function returning `Future<Either<L, R>>`.
  /// - [maxConcurrent]: Maximum number of concurrent executions. If `null`, no limit.
  ///
  /// ### Returns
  /// A [Future] containing either the first [Left] encountered, or a [Right] with all collected values.
  @useResult
  static Future<Either<L, BuiltList<R>>> parTraverseN<L, R, T>({
    required Iterable<T> values,
    required Future<Either<L, R>> Function() Function(T value) mapper,
    required int? maxConcurrent,
  }) =>
      parSequenceN<L, R>(
        functions: values.map(mapper),
        maxConcurrent: maxConcurrent,
      );

  /// Sequences all [Future<Either<L, R>>] functions with concurrency control.
  ///
  /// Runs the functions in parallel, but limits the number of concurrent executions to [maxConcurrent].
  /// If [maxConcurrent] is `null`, all functions run concurrently without limit.
  ///
  /// If any function returns a [Left], the operation short-circuits and returns that [Left].
  /// Otherwise, collects all [Right] values into a [BuiltList].
  ///
  /// The concurrency is controlled using a semaphore to prevent overwhelming the system.
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
  /// ### Parameters
  /// - [functions]: An iterable of functions that return `Future<Either<L, R>>`.
  /// - [maxConcurrent]: Maximum number of concurrent executions. If `null`, no limit.
  ///
  /// ### Returns
  /// A [Future] containing either the first [Left] encountered, or a [Right] with all collected values.
  @useResult
  static Future<Either<L, BuiltList<R>>> parSequenceN<L, R>({
    required Iterable<Future<Either<L, R>> Function()> functions,
    required int? maxConcurrent,
  }) async {
    final futureFunctions = functions.toList(growable: false);
    final semaphore = maxConcurrent != null ? Semaphore(maxConcurrent) : null;
    final token = _Token();

    Future<R> Function() run(Future<Either<L, R>> Function() f) {
      return () => Future.sync(f).then(
            (e) => e.getOrHandle((l) => throw ControlError<L>._(l, token)),
          );
    }

    Future<R> runWithPermit(Future<Either<L, R>> Function() f) {
      final action = run(f);
      return semaphore?.withPermit(action) ?? action();
    }

    return Future.wait(
      futureFunctions.map(runWithPermit),
      eagerError: true,
    )
        .then((values) => Either<L, BuiltList<R>>.right(values.build()))
        .onError<ControlError<L>>(
          (e, s) => Left(e._value),
          test: (e) => identical(e._token, token),
        );
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
  C fold<C>({
    required C Function(L value) ifLeft,
    required C Function(R value) ifRight,
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
  C foldLeft<C>(C initial, C Function(C acc, R element) rightOperation) =>
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
  @Deprecated('Use onLeft instead.')
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
  @Deprecated('Use onRight instead.')
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
  Either<L, C> map<C>(C Function(R value) f) => _foldInternal(
        ifLeft: (l) => Either<L, C>.left(l),
        ifRight: (r) => Either<L, C>.right(f(r)),
      );

  /// The given function is applied if this is a `Left`.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).mapLeft((_) => 'flower'); // Result: Right(12)
  /// Left<int, int>(12).mapLeft((_) => 'flower');  // Result: Left('flower')
  /// ```
  @useResult
  Either<C, R> mapLeft<C>(C Function(L value) f) => _foldInternal(
        ifLeft: (l) => Either<C, R>.left(f(l)),
        ifRight: (r) => Either<C, R>.right(r),
      );

  /// Binds the given function across [Right].
  ///
  /// If this is a [Right], returns the result of applying [f] to this [Right.value].
  /// Otherwise, returns itself.
  ///
  /// Slightly different from [map] in that [f] is expected to
  /// return an [Either] (which could be a [Left]).
  ///
  /// ### Example
  /// ```dart
  /// Right<String, int>(12).flatMap((v) => Right<String, String>('flower $v'));  // Result: Right('flower 12')
  /// Right<String, int>(12).flatMap((v) => Left<String, String>('flower $v'));   // Result: Left('flower 12')
  /// Left<String, int>('12').flatMap((v) => Right<String, String>('flower $v')); // Result: Left('12')
  /// Left<String, int>('12').flatMap((v) => Left<String, String>('flower $v'));  // Result: Left('12')
  /// ```
  @useResult
  Either<L, C> flatMap<C>(Either<L, C> Function(R value) f) => _foldInternal(
        ifLeft: (l) => Either<L, C>.left(l),
        ifRight: (r) => f(r),
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
  @useResult
  Either<C, D> bimap<C, D>({
    required C Function(L value) leftOperation,
    required D Function(R value) rightOperation,
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

  /// Alias of [isRightAnd].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).exists((v) => v > 10); // Result: true
  /// Left<int, int>(12).exists((v) => v > 10);  // Result: false
  /// ```
  @Deprecated('Use isRightAnd instead.')
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
  @useResult
  bool all(bool Function(R value) predicate) => _foldInternal(
        ifLeft: _const(true),
        ifRight: predicate,
      );

  /// Deprecated lazy fallback helper.
  ///
  /// This preserves the historical lazy behavior (`defaultValue` is evaluated only
  /// when this is [Left]), so it is **not** equivalent to `getOrDefault`, which is eager.
  ///
  /// Prefer:
  /// - [GetOrDefaultEitherExtension.getOrDefault] for eager fallback values.
  /// - [getOrHandle] for lazy fallback computation.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).getOrElse(() => 17); // Result: 12
  /// Left<int, int>(12).getOrElse(() => 17);  // Result: 17
  /// ```
  @Deprecated(
    'Use getOrDefault(value) for eager fallback, or getOrHandle for lazy fallback.',
  )
  R getOrElse(R Function() defaultValue) => getOrHandle((_) => defaultValue());

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
  @Deprecated('Use getOrNull instead.')
  R? orNull() => getOrNull();

  /// Returns the value from this [Right]
  /// or allows clients to transform the value of [Left] to the final result.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).getOrHandle((v) => 17);   // Result: 12
  /// Left<int, int>(12).getOrHandle((v) => v + 5); // Result: 17
  /// ```
  R getOrHandle(R Function(L value) defaultValue) => _foldInternal(
        ifLeft: defaultValue,
        ifRight: identity,
      );

  /// Returns the [Right.value] matching the given [predicate],
  /// or `null` if this is a [Left] or [Right.value] does not match.
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
  C when<C>({
    required C Function(Left<L, R> left) ifLeft,
    required C Function(Right<L, R> right) ifRight,
  }) {
    final self = this;
    return switch (self) { Left() => ifLeft(self), Right() => ifRight(self) };
  }

  /// Handle any error, potentially recovering from it, by mapping it to an [Either] value.
  ///
  /// Applies the given function [f] if this is a [Left], otherwise returns this if this is a [Right].
  /// This is like [flatMap] for the exception.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).handleErrorWith((v) => (v + 1).right<String>());   // Right(12)
  /// Right<int, int>(12).handleErrorWith((v) => (v + 1).toString().left()); // Right(12)
  /// Left<int, int>(12).handleErrorWith((v) => (v + 1).right<String>());    // Right(13)
  /// Left<int, int>(12).handleErrorWith((v) => (v + 1).toString().left());  // Left('13')
  /// ```
  @useResult
  Either<C, R> handleErrorWith<C>(Either<C, R> Function(L value) f) =>
      _foldInternal(
        ifLeft: f,
        ifRight: (v) => v.right<C>(),
      );

  /// Handle any error, potentially recovering from it, by mapping it to an [Either] value.
  ///
  /// Applies the given function [f] if this is a [Left] and return the result wrapped in a [Right],
  /// otherwise returns this if this is a [Right].
  @useResult
  Either<L, R> handleError(R Function(L value) f) => _foldInternal(
        ifLeft: (v) => f(v).right(),
        ifRight: (v) => v.right(),
      );

  /// Redeem an [Either] to an [Either] by resolving the error **or** mapping the value [R] to [C].
  ///
  /// [redeem] is derived from [map] and [handleError].
  /// This is functionally equivalent to `map(rightOperation).handleError(leftOperation)`.
  @useResult
  Either<L, C> redeem<C>({
    required C Function(L value) leftOperation,
    required C Function(R value) rightOperation,
  }) =>
      _foldInternal(
        ifLeft: (v) => leftOperation(v).right(),
        ifRight: (v) => rightOperation(v).right(),
      );

  /// Redeem an [Either] to an [Either] by resolving the error
  /// **or** mapping the value [R] to [C] **with** an [Either].
  ///
  /// [redeemWith] is derived from [flatMap] and [handleErrorWith].
  /// This is functionally equivalent to `flatMap(rightOperation).handleErrorWith(leftOperation)`.
  @useResult
  Either<C, D> redeemWith<C, D>({
    required Either<C, D> Function(L value) leftOperation,
    required Either<C, D> Function(R value) rightOperation,
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
/// The generic `bind` function returns an [Either]'s [Right.value]. Binding a
/// [Left] short-circuits the surrounding [Either.binding] or
/// [Either.futureBinding] scope with that left value.
///
/// Obtain a library-managed capability from the binding callback. A capability
/// supplied by [Either.binding] or [Either.futureBinding] is valid only for
/// that callback's lifetime, including asynchronous work returned by
/// [Either.futureBinding]. Invoking it after its scope has completed throws a
/// [StateError].
///
/// `EitherEffect` is contravariant in [L]: an effect accepting `num` errors can
/// be used where one accepting only `int` errors is required, while the unsafe
/// opposite assignment is rejected at compile time.
///
/// ### Example
/// ```dart
/// final result = Either<String, int>.binding((effect) {
///   final value = effect.bind(Either<String, int>.right(1));
///   return value + 1;
/// }); // Right(2)
/// ```
@monadComprehensions
typedef EitherEffect<L> = ({
  R Function<R>(Either<L, R> either) bind,
});

/// Internal control-flow signal raised when [EitherEffect] binds a [Left].
///
/// [Either.binding] and [Either.futureBinding] catch only signals belonging to
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

final class _BindingScope<L> {
  final _Token _token;
  var _phase = _BindingPhase.active;

  _BindingScope(this._token);

  void close() {
    _phase = _BindingPhase.closed;
  }

  void throwIfRaised() {
    if (_phase == _BindingPhase.raised) {
      throw StateError('Binding short-circuit was intercepted.');
    }
  }

  EitherEffect<L> openEitherEffect() {
    return (
      bind: <R>(Either<L, R> either) {
        if (_phase != _BindingPhase.active) {
          throw StateError('EitherEffect was used outside its binding scope.');
        }

        switch (either) {
          case Left(value: final value):
            _phase = _BindingPhase.raised;
            throw ControlError<L>._(value, _token);
          case Right(value: final value):
            return value;
        }
      }
    );
  }
}
