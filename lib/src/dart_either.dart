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

/// TODO
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

  /// TODO
  /// Must not catch [ControlError] in [block].
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

  /// TODO
  static Either<void, R> fromNullable<R extends Object>(R? value) =>
      value == null ? const Either.left(null) : Either.right(value);

  /// TODO
  /// Should not catch [ControlError] in [effect].
  static Future<Either<L, R>> bindingFuture<L, R>(
      FutureOr<R> Function(EitherEffect<L, R>) block) {
    final eitherEffect = _EitherEffectImpl<L, R>(_Token());

    return Future.sync(() => block(eitherEffect))
        .then((value) => Either<L, R>.right(value))
        .onError<ControlError<L>>(
          (e, s) => Either.left(e._value),
          test: (e) => identical(eitherEffect._token, e._token),
        );
  }

  /// TODO
  static Future<Either<L, R>> catchFutureError<L, R>(
    ErrorMapper<L> errorMapper,
    FutureOr<R> Function() f,
  ) =>
      Future.sync(f).then((value) => Either<L, R>.right(value)).onError<Object>(
          (e, s) => Either.left(errorMapper(e.throwIfFatal(), s)));

  /// TODO
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
      ' You cannot implement or extend Either class';
}

//
// Extensions
//

/// TODO
extension EitherExtensions<L extends Object, R> on Either<L, R> {
  /// TODO
  Future<R> asFuture() => fold(
        ifLeft: (e) => Future.error(e),
        ifRight: (v) => Future.value(v),
      );
}

/// TODO
extension ToEitherStreamExtension<R> on Stream<R> {
  /// TODO
  Stream<Either<L, R>> asEitherStream<L>(ErrorMapper<L> errorMapper) =>
      Either.catchStreamError<L, R>(errorMapper, this);
}

/// TODO
extension ToEitherObjectExtension<T> on T {
  /// TODO
  Either<T, Never> left() => Either.left(this);

  /// TODO
  Either<Never, T> right() => Either.right(this);
}

//
// Binding
//

/// Used for monad comprehensions.
@sealed
abstract class EitherEffect<L, R> {
  EitherEffect._();

  /// Attempt to get right value of either.
  /// Or throws a [ControlError].
  R bind(Either<L, R> either);

  /// Attempt to get right value of either.
  /// Or return a Future that completes with a [ControlError].
  Future<R> bindFuture(Future<Either<L, R>> future);
}

/// TODO
extension BindEitherExtension<L, R> on Either<L, R> {
  /// TODO
  R bind(EitherEffect<L, R> effect) => effect.bind(this);
}

/// Error thrown by [EitherEffect]. Should not be caught.
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
