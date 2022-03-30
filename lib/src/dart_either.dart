import 'dart:async';

import 'package:meta/meta.dart';

/// Map [error] and [stackTrace] to [T] value.
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

/// In day-to-day programming, it is fairly common to find ourselves writing functions that can fail.
/// For instance, querying a service may result in a connection issue, or some unexpected JSON response.
///
/// To communicate these errors, it has become common practice to throw exceptions; however,
/// exceptions are not tracked in any way, shape, or form by the compiler. To see what
/// kind of exceptions (if any) a function may throw, we have to dig through the source code.
/// Then, to handle these exceptions, we have to make sure we catch them at the call site. This
/// all becomes even more unwieldy when we try to compose exception-throwing procedures.
///
/// ```
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
abstract class Either<L, R> {
  const Either._();

  /// Create a [Left].
  const factory Either.left(L left) = Left;

  /// Create a [Right].
  const factory Either.right(R right) = Right;

  /// Evaluates the specified [block], wrap result in a [Right].
  /// If exception is thrown, invoke [errorMapper] and wrap result in a [Left].
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
  /// that mimics imperative statements (called `do-notation` in `Haskell`, `perform-notation` in `OCaml`, `computation expressions` in `F#`, and `for comprehension` in `Scala`).
  /// This is only syntactic sugar that disguises a monadic pipeline as a code block.
  ///
  // Translating the add function from the Maybe into Haskell can show this feature in action. A non-monadic version of add in Haskell looks like this:
  ///
  /// Calls the specified function [block] with [EitherEffect] as its parameter and returns its [Either].
  ///
  /// When inside a [Either.binding] block, calling the [EitherEffect.bind] function will attempt to unwrap the [Either]
  /// and locally return its [Right.value]. If the [Either] is a [Left],
  /// the binding block will terminate with that bind and return that failed-to-bind [Left].
  ///
  /// You can also use [BindEitherExtension.bind] instead of [EitherEffect.bind] for more convenience.
  /// **NOTE: Must not catch [ControlError] in [block].**
  ///
  /// Example:
  /// ```
  /// Either<ExampleErr, int> provideX() { ... }
  /// Either<ExampleErr, int> provideY() { ... }
  /// Either<ExampleErr, int> provideZ(int x, int y) { ... }
  ///
  /// Either<ExampleErr, int> result = Either<ExampleErr, int>.binding((e) {
  ///   int x = provideX().bind(e);
  ///   int y = provideY().bind(e);
  ///   int z = provideZ(x, y).bind(e);
  ///   return z;
  /// });
  /// ```
  factory Either.binding(R Function(EitherEffect<L, R>) block) {
    final eitherEffect = _EitherEffectImpl<L, R>(_Token());

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

  /// Returns a [Right] if [value] is not null.
  /// Returns a [Left] containing `null` otherwise.
  static Either<void, R> fromNullable<R extends Object>(R? value) =>
      value == null ? const Either.left(null) : Either.right(value);

  /// TODO(futureBinding)
  /// Should not catch [ControlError] in [effect].
  static Future<Either<L, R>> futureBinding<L, R>(
      FutureOr<R> Function(EitherEffect<L, R>) block) {
    final eitherEffect = _EitherEffectImpl<L, R>(_Token());

    return Future.sync(() => block(eitherEffect))
        .then((value) => Either<L, R>.right(value))
        .onError<ControlError<L>>(
          (e, s) => Either.left(e._value),
          test: (e) => identical(eitherEffect._token, e._token),
        );
  }

  /// Evaluates the specified [block], wrap result in a [Right].
  /// If exception is thrown, invoke [errorMapper] and wrap result in a [Left].
  static Future<Either<L, R>> catchFutureError<L, R>(
    ErrorMapper<L> errorMapper,
    FutureOr<R> Function() block,
  ) =>
      Future.sync(block)
          .then((value) => Either<L, R>.right(value))
          .onError<Object>(
              (e, s) => Either.left(errorMapper(e.throwIfFatal(), s)));

  /// TODO(catchStreamError)
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

  /// Returns `true` if this is a [Left], `false` otherwise.
  /// Used only for performance instead of fold.
  bool get isLeft;

  /// Returns `true` if this is a [Right], `false` otherwise.
  /// Used only for performance instead of fold.
  bool get isRight;

  /// Applies [ifLeft] if this is a [Left] or [ifRight] if this is a [Right].
  ///
  /// Example:
  /// ```
  /// final Either<Exception, Value> result = possiblyFailingOperation();
  /// result.fold(
  ///   ifLeft: (value) => print('operation failed with $value') ,
  ///   ifRight: (value) => print('operation succeeded with $value'),
  /// );
  /// ```
  ///
  /// [ifLeft] is the function to apply if this is a [Left].
  /// [ifRight] is the function to apply if this is a [Right].
  /// Returns the results of applying the function.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  C fold<C>({
    required C Function(L) ifLeft,
    required C Function(R) ifRight,
  }) {
    final self = this;
    if (self is Left<L>) {
      return ifLeft(self.value);
    }
    if (self is Right<R>) {
      return ifRight(self.value);
    }
    throw _InvalidEitherError<L, R>(self);
  }

  /// If this is a [Right], applies [ifRight] with [initial] and [Right.value].
  /// Returns [initial] otherwise.
  ///
  /// Example:
  /// ```
  /// final Either<Exception, Value> result = possiblyFailingOperation();
  /// final Value initial;
  /// Value combine(Value acc, Value v) {};
  ///
  /// result.foldLeft(initial, combine);
  /// ```
  C foldLeft<C>(C initial, C Function(C, R) rightOperation) => fold(
        ifLeft: _const(initial),
        ifRight: (r) => rightOperation(initial, r),
      );

  /// If this is a `Left`, then return the left value in `Right` or vice versa.
  ///
  /// Example:
  /// ```
  /// Left('left').swap();   // Result: Right('left')
  /// Right('right').swap(); // Result: Left('right')
  /// ```
  Either<R, L> swap() => fold(
        ifLeft: (l) => Either.right(l),
        ifRight: (r) => Either.left(r),
      );

  /// The given function is applied if this is a `Right`.
  ///
  /// Example:
  /// ```
  /// Right(12).map((_) => 'flower'); // Result: Right('flower')
  /// Left(12).map((_) => 'flower');  // Result: Left(12)
  /// ```
  Either<L, C> map<C>(C Function(R) f) => when(
        ifLeft: _identity,
        ifRight: (r) => Either.right(f(r.value)),
      );

  /// The given function is applied if this is a `Left`.
  ///
  /// Example:
  /// ```
  /// Right(12).mapLeft((_) => 'flower'); // Result: Right(12)
  /// Left(12).mapLeft((_) => 'flower');  // Result: Left('flower')
  /// ```
  Either<C, R> mapLeft<C>(C Function(L) f) => when(
        ifLeft: (l) => Either.left(f(l.value)),
        ifRight: _identity,
      );

  /// Binds the given function across [Right].
  ///
  /// If this is a [Right], returns the result of applying [f] to this [Right.value].
  /// Otherwise, returns itself.
  ///
  /// Slightly different from [map] in that [f] is expected to
  /// return an [Either] (which could be a [Left]).
  ///
  /// Example:
  /// ```
  /// Right(12).map((v) => Either.right('flower $v')); // Result: Right('flower 12')
  /// Right(12).map((v) => Either.left('flower $v')); // Result: Left('flower 12')
  ///
  /// Left(12).map((_) => Either.right('flower $v'));  // Result: Left(12)
  /// Left(12).map((_) => Either.left('flower $v'));  // Result: Left(12)
  /// ```
  Either<L, C> flatMap<C>(Either<L, C> Function(R) f) => when(
        ifLeft: _identity,
        ifRight: (r) => f(r.value),
      );

  /// Map over Left and Right of this Either
  Either<C, D> bimap<C, D>(
    C Function(L) leftOperation,
    D Function(R) rightOperation,
  ) =>
      fold(
        ifLeft: (l) => Either.left(leftOperation(l)),
        ifRight: (r) => Either.right(rightOperation(r)),
      );

  /// Returns `false` if [Left] or returns the result of the application of
  /// the given [predicate] to the [Right] value.
  ///
  /// Example:
  /// ```
  /// Right(12).exists((v) => v > 10); // Result: true
  /// Right(7).exists((v) => v > 10);  // Result: false
  ///
  /// final Either<int, int> left = Left(12);
  /// left.exists((v) => v > 10);      // Result: false
  /// ```
  bool exists(bool Function(R) predicate) => fold(
        ifLeft: _const(false),
        ifRight: predicate,
      );

  /// Returns the value from this [Right] or the given argument if this is a [Left].
  ///
  /// Example:
  /// ```
  /// Right(12).getOrElse(() => 17); // Result: 12
  /// Left(12).getOrElse(() => 17);  // Result: 17
  /// ```
  R getOrElse(R Function() defaultValue) => fold(
        ifLeft: (_) => defaultValue(),
        ifRight: _identity,
      );

  /// Returns the right value if it exists, otherwise `null`
  ///
  /// Example:
  /// ```
  /// final Either<int, int> right = Right(12).orNull(); // Result: 12
  /// final Either<int, int> left = Left(12).orNull();   // Result: null
  /// ```
  R? orNull() => fold(
        ifLeft: _const(null),
        ifRight: _identity,
      );

  /// Returns the value from this [Either.Right] or allows clients to transform [Either.Left] to [Either.Right] while providing access to
  /// the value of [Either.Left].
  ///
  /// Example:
  /// ```
  /// Right(12).getOrHandle((v) => 17); // Result: 12
  /// Left(12).getOrHandle((v) => v + 5); // Result: 17
  /// ```
  R getOrHandle(R Function(L) defaultValue) => fold(
        ifLeft: defaultValue,
        ifRight: _identity,
      );

  /// Applies [ifLeft] if this is a [Left] or [ifRight] if this is a [Right].
  ///
  /// This is quite similar to [fold], but with [fold], arguments will
  /// be called with [Right.value] or [Left.value], while the arguments of [when]
  /// will be called with [Right] or [Left] itself.
  ///
  /// Example:
  /// ```
  /// final Either<Exception, Value> result = possiblyFailingOperation();
  /// result.when(
  ///   ifLeft: (left) => print('operation failed with ${left.value}') ,
  ///   ifRight: (right) => print('operation succeeded with ${right.value}'),
  /// );
  /// ```
  ///
  /// [ifLeft] is the function to apply if this is a [Left].
  /// [ifRight] is the function to apply if this is a [Right].
  /// Returns the results of applying the function.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  C when<C>({
    required C Function(Left<L>) ifLeft,
    required C Function(Right<R>) ifRight,
  }) {
    final self = this;
    if (self is Left<L>) {
      return ifLeft(self);
    }
    if (self is Right<R>) {
      return ifRight(self);
    }
    throw _InvalidEitherError<L, R>(self);
  }
}

/// The left side of the disjoint union, as opposed to the [Right] side.
@sealed
class Left<T> extends Either<T, Never> {
  /// The value inside [Left].
  final T value;

  /// Construct a [Left] with [value].
  const Left(this.value) : super._();

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Left && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Either.Left($value)';
}

/// The right side of the disjoint union, as opposed to the [Left] side.
@sealed
class Right<T> extends Either<Never, T> {
  /// The value inside [Right].
  final T value;

  /// Construct a [Right] with [value].
  const Right(this.value) : super._();

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Right &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Either.Right($value)';
}

class _InvalidEitherError<L, R> extends Error {
  final Either<L, R> invalid;

  _InvalidEitherError(this.invalid);

  @override
  String toString() =>
      'Unknown $invalid. $invalid must be either a Right<$R> or Left<$L>.'
      ' Cannot implement or extend Either class';
}

//
// Extensions
//

/// Provide [toFuture] extension on [Either].
extension AsFutureEitherExtension<L extends Object, R> on Either<L, R> {
  /// Convert this [Either] to a [Future].
  /// If [this] is [Right], the Future will complete with [Right.value].
  /// If [this] is [Left], the Future will complete with [Left.value] as an error.
  Future<R> toFuture() => fold(
        ifLeft: (e) => Future.error(e),
        ifRight: (v) => Future.value(v),
      );
}

/// Provide [toEitherStream] extension on [Stream].
extension ToEitherStreamExtension<R> on Stream<R> {
  /// TODO(catchStreamError)
  Stream<Either<L, R>> toEitherStream<L>(ErrorMapper<L> errorMapper) =>
      Either.catchStreamError<L, R>(errorMapper, this);
}

/// Provide [left] and [right] extensions on any types.
extension ToEitherObjectExtension<T> on T {
  /// Return a [Left] that contains [this] value.
  /// Can cast returned result to any `Either<T, ...>` type.
  ///
  /// For example:
  /// ```
  /// Either<int, Never> e1 = 1.left();
  /// Either<int, String> e2 = 1.left();
  /// Either<int, dynamic> e3 = 1.left();
  /// ``
  Either<T, Never> left() => Either.left(this);

  /// Return a [Right] that contains [this] value.
  /// Can cast returned result to any `Either<..., T>` type.
  ///
  /// For example:
  /// ```
  /// Either<Never, int> e1 = 1.right();
  /// Either<String, int> e2 = 1.right();
  /// Either<dynamic, int> e3 = 1.right();
  /// ``
  Either<Never, T> right() => Either.right(this);
}

//
// Binding
//

/// Used for monad comprehensions.
@sealed
abstract class EitherEffect<L, R> {
  EitherEffect._();

  /// Attempt to get right value of [either].
  /// Or throws a [ControlError].
  R bind(Either<L, R> either);

  /// Attempt to get right value of [eitherFuture].
  /// Or return a [Future] that completes with a [ControlError].
  Future<R> bindFuture(Future<Either<L, R>> eitherFuture);
}

/// Provide [ensure] extension on [EitherEffect].
extension EnsureEitherEffectExtension<L, R> on EitherEffect<L, R> {
  /// Ensure check if the [value] is `true`,
  /// and if it is it allows the `Either.binding(...)` to continue.
  /// In case it is `false`, then it short-circuits the binding and returns
  /// the provided value by [orLeft] inside a [Left].
  ///
  /// ```
  ///   final res = Either<String, int>.binding((e) {
  ///     e.ensure(true, () => "");
  ///     print("ensure(true) passes");
  ///     e.ensure(false, () => "failed");
  ///     return 1;
  ///   });
  /// // print: "ensure(true) passes"
  /// // res: Either.Left("failed")
  /// ```
  void ensure(bool value, L Function() orLeft) =>
      value ? null : bind(orLeft().left());
}

/// Provide [ensureNotNull] extension on [EitherEffect].
extension EnsureNotNullEitherEffectExtension<L, R extends Object>
    on EitherEffect<L, R> {
  /// Ensures that [value] is not null.
  /// When the value is not null, then it will be returned as non null and the check value is now smart-checked to non-null.
  /// Otherwise, if the [value] is null then the `Either.binding(...)` will short-circuit with [orLeft] inside of [Left].
  ///
  /// ```
  ///   final res = Either<String, int>.binding((e) {
  ///     int? x = 1;
  ///     e.ensureNotNull(x, () => "passes");
  ///     print(x);
  ///     e.ensureNotNull(null, () => "failed");
  ///     return 1;
  ///   });
  ///   print(res);
  /// // println: "1"
  /// // res: Either.Left("failed")
  /// ```
  R ensureNotNull(R? value, L Function() orLeft) =>
      value ?? bind(orLeft().left());
}

/// Provide [bind] extension on an [Either].
extension BindEitherExtension<L, R> on Either<L, R> {
  /// Attempt to get right value of [this].
  /// Or throws a [ControlError].
  R bind(EitherEffect<L, R> effect) => effect.bind(this);
}

/// Provide [bind] extension on a [Future] of [Either].
extension BindEitherFutureExtension<L, R> on Future<Either<L, R>> {
  /// Attempt to get right value of [this].
  /// Or return a [Future] that completes with a [ControlError].
  Future<R> bind(EitherEffect<L, R> effect) => effect.bindFuture(this);
}

/// Error thrown by [EitherEffect].
/// Must be not caught.
/// Cannot implement or extend this class.
@sealed
class ControlError<T> extends Error {
  final _Token _token;

  final T _value;

  ControlError._(this._value, this._token);

  @override
  String toString() => 'ControlError($_value, $_token)';
}

/// Class that represents a unique token by hash comparison **/
class _Token {
  @override
  String toString() => 'Token(${hashCode.toRadixString(16)})';
}

class _EitherEffectImpl<L, R> implements EitherEffect<L, R> {
  final _Token _token;

  _EitherEffectImpl(this._token);

  @override
  R bind(Either<L, R> either) =>
      either.getOrHandle((v) => throw ControlError._(v, _token));

  @override
  Future<R> bindFuture(Future<Either<L, R>> future) => future.then(bind);
}
