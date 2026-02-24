import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import 'binding.dart';
import 'extensions.dart';
import 'utils/semaphore.dart';

/// Map [error] and [stackTrace] to a [T] value.
typedef ErrorMapper<T> = T Function(Object error, StackTrace stackTrace);

extension on Object {
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Object throwIfFatal() {
    if (this is ControlError) {
      throw this;
    }
    return this;
  }
}

T _identity<T>(T t) => t;

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
  /// Calls the specified function [block] with [EitherEffect] as its parameter and returns its [Either].
  ///
  /// When inside a [Either.binding] block, calling the [EitherEffect.bind] function will attempt to unwrap the [Either]
  /// and locally return its [Right.value]. If the [Either] is a [Left],
  /// the binding block will terminate with that bind and return that failed-to-bind [Left].
  ///
  /// You can also use [BindEitherExtension.bind] instead of [EitherEffect.bind] for more convenience.
  ///
  /// ### Example
  /// ```dart
  /// class ExampleError {}
  ///
  /// Either<ExampleError, int> provideX() { ... }
  /// Either<ExampleError, int> provideY() { ... }
  /// Either<ExampleError, int> provideZ(int x, int y) { ... }
  ///
  /// Either<ExampleError, int> result = Either<ExampleError, int>.binding((e) {
  ///   int x = provideX().bind(e);       // or use `e.bind(provideX())`.
  ///   int y = e.bind(provideY());       // or use `provideY().bind(e)`.
  ///   int z = provideZ(x, y).bind(e);   // or use `e.bind(provideZ(x, y))`.
  ///   return z;
  /// });
  /// ```
  ///
  /// ### NOTE
  /// - Do NOT catch [ControlError] in [block].
  /// - Do NOT throw any errors inside [block].
  /// - Use [Either.catchError], [Either.catchFutureError] or [Either.catchStreamError] to catch error,
  ///   then use [EitherEffect.bind] to unwrap the [Either].
  ///
  /// ```dart
  /// /// This function can throw an error.
  /// int canThrowAnError() { ... }
  ///
  /// // DON'T
  /// Either<ExampleError, int> result = Either<ExampleError, int>.binding((e) {
  ///   int value = canThrowAnError();
  /// });
  ///
  /// // DO
  /// ExampleError toExampleError(Object e, StackTrace st) { ... }
  ///
  /// Either<ExampleError, int> result = Either<ExampleError, int>.binding((e) {
  ///   int value = Either<ExampleError, int>.catchError(
  ///     toExampleError,
  ///     canThrowAnError
  ///   ).bind(e);
  /// });
  /// ```
  factory Either.binding(
      @monadComprehensions R Function(EitherEffect<L> effect) block) {
    final eitherEffect = _EitherEffectImpl<L>(_Token());

    try {
      return Either.right(block(eitherEffect));
    } on ControlError<L> catch (e) {
      if (identical(eitherEffect._token, e._token)) {
        return Either.left(e._value);
      } else {
        rethrow;
      }
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
  /// Calls the specified function [block] with [EitherEffect] as its parameter and returns its [Either] wrapped in a [Future].
  ///
  /// When inside a [Either.futureBinding] block, calling the [EitherEffect.bind] function will attempt to unwrap the [Either]
  /// and locally return its [Right.value]. If the [Either] is a [Left],
  /// the binding block will terminate with that bind and return that failed-to-bind [Left].
  ///
  /// When inside a [Either.futureBinding] block, calling the [BindFutureEitherEffectExtension.bindFuture] function
  /// will attempt to will attempt to unwrap the [Either] inside the [Future].
  /// and locally return its [Right.value] wrapped in a [Future].
  /// If the [Either] is a [Left], the binding block will terminate with that bind and return that failed-to-bind [Left].
  /// If the [Future] completes with an error, it will not be handled.
  ///
  /// You can also use [BindEitherExtension.bind] instead of [EitherEffect.bind],
  /// [BindEitherFutureExtension.bind] instead of [BindFutureEitherEffectExtension.bindFuture] for more convenience.
  ///
  /// ### Example
  /// ```dart
  /// class ExampleError {}
  ///
  /// Either<ExampleError, int> provideX() { ... }
  /// Future<Either<ExampleError, int>> provideY() { ... }
  /// Future<Either<ExampleError, int>> provideZ(int x, int y) { ... }
  ///
  /// Future<Either<ExampleError, int>> result = Either.futureBinding<ExampleError, int>((e) async {
  ///   int x = provideX().bind(e);                   // or use `e.bind(provideX())`.
  ///   int y = await e.bindFuture(provideY());       // or use `await provideY().bind(e)`.
  ///   int z = await provideZ(x, y).bind(e);         // or use `await e.bindFuture(provideZ(x, y))`.
  ///   return z;
  /// });
  /// ```
  ///
  /// ### NOTE
  /// - Do NOT catch [ControlError] in [block].
  /// - Do NOT throw any errors inside [block].
  /// - When using [BindFutureEitherEffectExtension.bindFuture], if the [Future] completes with an error, it will not be handled.
  /// - Use [Either.catchError], [Either.catchFutureError] or [Either.catchStreamError] to catch error,
  ///   then use [EitherEffect.bind] and [BindFutureEitherEffectExtension.bindFuture] to unwrap the [Either].
  ///
  /// ```dart
  /// /// This function can throw an error.
  /// int canThrowAnError() { ... }
  /// Future<int> canReturnAnErrorFuture() { ... }
  /// Future<int> errorFuture = Future.error(Exception());
  ///
  /// // DON'T
  /// Future<Either<ExampleError, int>> result = Either.futureBinding<ExampleError, int>((e) async {
  ///   int value1 = canThrowAnError();                // DON'T
  ///   int value2 = await canReturnAnErrorFuture();   // DON'T
  ///   int value3 = await errorFuture;                // DON'T
  ///   return value1 + value2 + value3;
  /// });
  ///
  /// // DO
  /// ExampleError toExampleError(Object e, StackTrace st) { ... }
  ///
  /// Future<Either<ExampleError, int>> result = Either.futureBinding<ExampleError, int>((e) async {
  ///   int value1 = Either<ExampleError, int>.catchError(
  ///     toExampleError,
  ///     canThrowAnError
  ///   ).bind(e);
  ///
  ///   int value2 = await Either.catchFutureError<ExampleError, int>(
  ///     toExampleError,
  ///     canReturnAnErrorFuture
  ///   ).bind(e);
  ///
  ///   int value3 = await Either.catchFutureError<ExampleError, int>(
  ///     toExampleError,
  ///     () => errorFuture
  ///   ).bind(e);
  ///
  ///   return value1 + value2 + value3;
  /// });
  /// ```
  static Future<Either<L, R>> futureBinding<L, R>(
      @monadComprehensions FutureOr<R> Function(EitherEffect<L> effect) block) {
    final eitherEffect = _EitherEffectImpl<L>(_Token());

    return Future.sync(() => block(eitherEffect))
        .then((value) => Either<L, R>.right(value))
        .onError<ControlError<L>>(
          (e, s) => Either.left(e._value),
          test: (e) => identical(eitherEffect._token, e._token),
        );
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

  /// TODO(parTraverseN)
  @experimental
  static Future<Either<L, BuiltList<R>>> parTraverseN<L, R, T>(
    Iterable<T> values,
    Future<Either<L, R>> Function() Function(T value) mapper,
    int? n,
  ) =>
      parSequenceN<L, R>(values.map(mapper), n);

  /// TODO(parSequenceN)
  @experimental
  static Future<Either<L, BuiltList<R>>> parSequenceN<L, R>(
    Iterable<Future<Either<L, R>> Function()> functions,
    int? n,
  ) async {
    final futureFunctions = functions.toList(growable: false);
    final semaphore = Semaphore(n ?? futureFunctions.length);
    final token = _Token();

    Future<R> Function() run(Future<Either<L, R>> Function() f) {
      return () => Future.sync(f).then(
            (e) => e.getOrHandle((l) => throw ControlError<L>._(l, token)),
          );
    }

    Future<R> runWithPermit(Future<Either<L, R>> Function() f) =>
        semaphore.withPermit(run(f));

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

  /// The given function is applied as a fire and forget effect if this is a [Left].
  /// When applied the result is ignored and the original [Either] value is returned.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).tapLeft((_) => println('flower')); // Result: Right(12)
  /// Left<int, int>(12).tapLeft((_) => println('flower'));  // Result: prints 'flower' and returns: Left(12)
  /// ```
  @useResult
  Either<L, R> tapLeft(void Function(L value) f) {
    if (this case Left(value: final value)) {
      f(value);
    }
    return this;
  }

  /// The given function is applied as a fire and forget effect if this is a [Right].
  /// When applied the result is ignored and the original [Either] value is returned.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).tapLeft((_) => println('flower')); // Result: prints 'flower' and returns: Right(12)
  /// Left<int, int>(12).tapLeft((_) => println('flower'));  // Result: Left(12)
  /// ```
  @useResult
  Either<L, R> tap(void Function(R value) f) {
    if (this case Right(value: final value)) {
      f(value);
    }
    return this;
  }

  /// The given function is applied if this is a `Right`.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).map((_) => 'flower'); // Result: Right('flower')
  /// Left<int, int>(12).map((_) => 'flower');  // Result: Left(12)
  /// ```
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
  /// Right<int, int>(12).exists((v) => v > 10); // Result: true
  /// Right<int, int>(7).exists((v) => v > 10);  // Result: false
  ///
  /// Left<int, int>(12).exists((v) => v > 10);  // Result: false
  /// Left<int, int>(12).exists((v) => v < 10);  // Result: false
  /// ```
  @useResult
  bool exists(bool Function(R value) predicate) => _foldInternal(
        ifLeft: _const(false),
        ifRight: predicate,
      );

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

  /// Returns the value from this [Right] or the given argument if this is a [Left].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).getOrElse(() => 17); // Result: 12
  /// Left<int, int>(12).getOrElse(() => 17);  // Result: 17
  /// ```
  R getOrElse(R Function() defaultValue) => _foldInternal(
        ifLeft: (_) => defaultValue(),
        ifRight: _identity,
      );

  /// Returns the [Right]'s value if it exists, otherwise `null`.
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).orNull(); // Result: 12
  /// Left<int, int>(12).orNull();  // Result: null
  /// ```
  R? orNull() => _foldInternal(
        ifLeft: _const(null),
        ifRight: _identity,
      );

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
        ifRight: _identity,
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

/// Monad comprehensions is the name for a programming idiom available
/// in multiple languages like `JavaScript`, `F#`, `Scala`, or `Haskell`.
/// The purpose of monad comprehensions is to compose sequential chains
/// of actions in a style that feels natural for programmers of all backgrounds.
/// They’re similar to `coroutines` or `async`/`await`, but extensible to existing and new types!
const monadComprehensions = _MonadComprehensions();

class _MonadComprehensions {
  const _MonadComprehensions();
}

/// Used for monad comprehensions.
/// Cannot implement or extend this class.
@sealed
sealed class EitherEffect<L> {
  EitherEffect._();

  /// Attempt to get right value of [either].
  /// Or throws a [ControlError].
  @monadComprehensions
  R bind<R>(Either<L, R> either);
}

/// Error thrown by [EitherEffect].
/// Must not be caught.
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

class _EitherEffectImpl<L> extends EitherEffect<L> {
  final _Token _token;

  _EitherEffectImpl(this._token) : super._();

  @override
  R bind<R>(Either<L, R> either) =>
      either.getOrHandle((v) => throw ControlError._(v, _token));
}
