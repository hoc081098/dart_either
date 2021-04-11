import 'dart:async';

import 'package:meta/meta.dart';

@immutable
@sealed
abstract class Either<L, R> {
  const Either._();

  const factory Either.left(L left) = Left;

  const factory Either.right(R right) = Right;

  static Either<void, R> fromNullable<R>(R? value) =>
      value == null ? Either.left(null) : Either.right(value);

  static Either<L, R> catchError<L extends Object, R>(R Function() f) {
    try {
      return Either.right(f());
    } on L catch (e) {
      return Either.left(e);
    }
  }

  static Future<Either<L, R>> catchFutureError<L extends Object, R>(
          Future<R> Function() f) =>
      f()
          .then((value) => Either<L, R>.right(value))
          .onError<L>((error, _) => Either.left(error));

  static Stream<Either<L, R>> catchStreamError<L extends Object, R>(
          Stream<R> stream) =>
      stream.transform(
        StreamTransformer<R, Either<L, R>>.fromHandlers(
          handleData: (data, sink) => sink.add(Either.right(data)),
          handleError: (e, s, sink) {
            if (e is L) {
              sink.add(Either.left(e));
            } else {
              sink.addError(e, s);
            }
          },
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
}

/// The left side of the disjoint union, as opposed to the [Right] side.
class Left<T> extends Either<T, Never> {
  final T value;

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
  final T value;

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

extension ToEitherStreamExtension<R> on Stream<R> {
  Stream<Either<L, R>> either<L extends Object>() =>
      Either.catchStreamError<L, R>(this);
}

Either<Object, String> catchObject() {
  return Either.catchError(() {
    throw Exception('Test');
  });
}

Either<Exception, String> catchException() {
  return Either.catchError<Exception, String>(() {
    throw 'A string';
  });
}

Future<Either<Object, String>> catchObjectAsync() {
  return Either.catchFutureError(() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    throw Exception('Test 2');
  });
}

Future<Either<Exception, String>> catchExceptionAsync() {
  return Either.catchFutureError(() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    throw 'A string';
  });
}

Stream<Either<Object, int>> getStream() {
  return Stream.fromIterable([1, 2, 3, 4])
      .map((v) => v == 3 ? throw Exception('Error...') : v)
      .either();
}

void main() async {
  catchObject().fold((e) => print('Error: $e'), print);
  (await catchObjectAsync()).fold((e) => print('Error: $e'), print);

  try {
    catchException().fold((e) => print('Error: $e'), print);
  } catch (e) {
    print('Unhandled $e');
  }
  try {
    (await catchExceptionAsync()).fold((e) => print('Error: $e'), print);
  } catch (e) {
    print('Unhandled $e');
  }

  getStream().listen(print);
}
