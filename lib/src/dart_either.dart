import 'dart:async';

import 'package:meta/meta.dart';

/// Map [error] and [stackTrace] to [T] value.
typedef ErrorMapper<T> = T Function(Object error, StackTrace stackTrace);

/// TODO
@immutable
@sealed
abstract class Either<L, R> {
  const Either._();

  /// TODO
  const factory Either.left(L left) = Left;

  /// TODO
  const factory Either.right(R right) = Right;

  /// Invoke [f] and wrap result in [Right]
  factory Either.catchError(ErrorMapper<L> errorMapper, R Function() f) {
    try {
      return Either.right(f());
    } catch (e, s) {
      return Either.left(errorMapper(e, s));
    }
  }

  /// Should not catch [ControlError] in [effect].
  factory Either.binding(R Function(EitherEffect<L, R>) effect) {
    try {
      return Either.right(effect(_EitherEffectImpl<L, R>()));
    } on ControlError<L> catch (e) {
      return Either.left(e._value);
    }
  }

  /// TODO
  static Either<void, R> fromNullable<R>(R? value) =>
      value == null ? Either.left(null) : Either.right(value);

  /// Should not catch [ControlError] in [effect].
  static Future<Either<L, R>> bindingFuture<L, R>(
          FutureOr<R> Function(EitherEffect<L, R>) effect) =>
      Future.sync(() => effect(_EitherEffectImpl<L, R>()))
          .then((value) => Either<L, R>.right(value))
          .onError<ControlError<L>>((e, s) => Either.left(e._value));

  /// TODO
  static Future<Either<L, R>> catchFutureError<L, R>(
    ErrorMapper<L> errorMapper,
    FutureOr<R> Function() f,
  ) =>
      Future.sync(f)
          .then((value) => Either<L, R>.right(value))
          .onError<Object>((e, s) => Either.left(errorMapper(e, s)));

  /// TODO
  static Stream<Either<L, R>> catchStreamError<L, R>(
    ErrorMapper<L> errorMapper,
    Stream<R> stream,
  ) =>
      stream.transform(
        StreamTransformer<R, Either<L, R>>.fromHandlers(
          handleData: (data, sink) => sink.add(Either.right(data)),
          handleError: (e, s, sink) => sink.add(Either.left(errorMapper(e, s))),
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
  /// final Either<Exception, Value> result = possiblyFailingOperation()
  /// result.fold(
  ///   (value) => print('operation failed with $value') ,
  ///   (value) => print('operation succeeded with $value'),
  /// )
  /// ```
  ///
  /// [ifLeft] is the function to apply if this is a [Left].
  /// [ifRight] is the function to apply if this is a [Right].
  /// Returns the results of applying the function.
  C fold<C>(
    C Function(L) ifLeft,
    C Function(R) ifRight,
  ) {
    final self = this;
    return self is Left<L>
        ? ifLeft(self.value)
        : ifRight((self as Right<R>).value);
  }

  /// TODO
  C foldLeft<C>(C initial, C Function(C, R) rightOperation) =>
      fold((_) => initial, (r) => rightOperation(initial, r));

  /// If this is a `Left`, then return the left value in `Right` or vice versa.
  ///
  /// Example:
  /// ```
  /// Left('left').swap()   // Result: Right('left')
  /// Right('right').swap() // Result: Left('right')
  /// ```
  Either<R, L> swap() => fold((l) => Either.right(l), (r) => Either.left(r));

  /// The given function is applied if this is a `Right`.
  ///
  /// Example:
  /// ```
  /// Right(12).map((_) => 'flower') // Result: Right('flower')
  /// Left(12).map((_) => 'flower')  // Result: Left(12)
  /// ```
  Either<L, C> map<C>(C Function(R) f) =>
      fold((l) => Either.left(l), (r) => Either.right(f(r)));

  /// The given function is applied if this is a `Left`.
  ///
  /// Example:
  /// ```
  /// Right(12).mapLeft((_) => 'flower') // Result: Right(12)
  /// Left(12).mapLeft((_) => 'flower')  // Result: Left('flower')
  /// ```
  Either<C, R> mapLeft<C>(C Function(L) f) =>
      fold((l) => Either.left(f(l)), (r) => Either.right(r));

  /// TODO
  Either<L, C> flatMap<C>(Either<L, C> Function(R) f) =>
      fold((l) => Either.left(l), f);

  /// Map over Left and Right of this Either
  Either<C, D> bimap<C, D>(
    C Function(L) leftOperation,
    D Function(R) rightOperation,
  ) =>
      fold(
        (l) => Either.left(leftOperation(l)),
        (r) => Either.right(rightOperation(r)),
      );

  /// Returns `false` if [Left] or returns the result of the application of
  /// the given [predicate] to the [Right] value.
  ///
  /// Example:
  /// ```
  /// Right(12).exists((v) => v > 10) // Result: true
  /// Right(7).exists((v) => v > 10)  // Result: false
  ///
  /// final Either<int, int> left = Left(12)
  /// left.exists((v) => v > 10)      // Result: false
  /// ```
  bool exists(bool Function(R) predicate) => fold((l) => false, predicate);

  /// Returns the value from this [Right] or the given argument if this is a [Left].
  ///
  /// Example:
  /// ```
  /// Right(12).getOrElse(() => 17) // Result: 12
  /// Left(12).getOrElse(() => 17)  // Result: 17
  /// ```
  R getOrElse(R Function() defaultValue) =>
      fold((l) => defaultValue(), (r) => r);

  /// Returns the right value if it exists, otherwise `null`
  ///
  /// Example:
  /// ```
  /// final Either<int, int> right = Right(12).orNull() // Result: 12
  /// final Either<int, int> left = Left(12).orNull()   // Result: null
  /// ```
  R? orNull() => fold((l) => null, (r) => r);

  /// Returns the value from this [Either.Right] or allows clients to transform [Either.Left] to [Either.Right] while providing access to
  /// the value of [Either.Left].
  ///
  /// Example:
  /// ```
  /// Right(12).getOrHandle((v) => 17) // Result: 12
  /// Left(12).getOrHandle((v) => v + 5) // Result: 17
  /// ```
  R getOrHandle(R Function(L) defaultValue) => fold(defaultValue, (r) => r);
}

/// The left side of the disjoint union, as opposed to the [Right] side.
class Left<T> extends Either<T, Never> {
  /// TODO
  final T value;

  /// TODO
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
class Right<T> extends Either<Never, T> {
  /// TODO
  final T value;

  /// TODO
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

/// TODO
extension EitherExtensions<L extends Object, R> on Either<L, R> {
  /// TODO
  Future<R> asFuture() => fold((e) => Future.error(e), (v) => Future.value(v));
}

/// TODO
extension ToEitherStreamExtension<R> on Stream<R> {
  /// TODO
  Stream<Either<L, R>> asEitherStream<L>(ErrorMapper<L> errorMapper) =>
      Either.catchStreamError<L, R>(errorMapper, this);
}

/// Used for monad comprehensions.
@sealed
abstract class EitherEffect<L, R> {
  /// Attempt to get right value of either.
  /// Or throws a [ControlError].
  R bind(Either<L, R> either);

  /// Attempt to get right value of either.
  /// Or return a Future that completes with a [ControlError].
  Future<R> bindFuture(Future<Either<L, R>> future);
}

/// TODO
extension EitherEffectExtensions<L, R> on EitherEffect<L, R> {
  /// TODO
  R operator <<(Either<L, R> either) => bind(either);
}

/// Error thrown by [EitherEffect]. Should not be caught.
@sealed
class ControlError<T> {
  final T _value;

  const ControlError._(this._value);
}

class _EitherEffectImpl<L, R> implements EitherEffect<L, R> {
  @override
  R bind(Either<L, R> either) =>
      either.getOrHandle((v) => throw ControlError._(v));

  @override
  Future<R> bindFuture(Future<Either<L, R>> future) => future.then(bind);
}
