import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';
import 'semaphore_test.dart' as semaphore_test;

Object takeOnlyError(Object error, StackTrace stackTrace) => error;

class MyControlError<L> implements ControlError<L> {
  @override
  StackTrace? get stackTrace => null;
}

void main() {
  semaphore_test.main();

  const leftOf1 = Left(1);
  const rightOf1 = Right(1);
  final exception = Exception();

  group('Either', () {
    test('isLeft', () {
      expect(leftOf1.isLeft, isTrue);
      expect(rightOf1.isLeft, isFalse);
    });

    test('isRight', () {
      expect(leftOf1.isRight, isFalse);
      expect(rightOf1.isRight, isTrue);
    });

    group('Right', () {
      test('==', () {
        expect(Right<int>(1) == Either<Never, int>.right(1), isTrue);
        expect(Right<int>(1) == Right<num>(1), isFalse);
      });

      test('hashCode', () {
        expect(Right<int>(1).hashCode == Either<Never, int>.right(1).hashCode,
            isTrue);
        expect(Right<int>(1).hashCode == Right<num>(1).hashCode, isTrue);
      });

      test('toString', () {
        expect('Either.Right(1)', rightOf1.toString());
        expect('Either.Right([1, 2, 3])', Right([1, 2, 3]).toString());
      });
    });

    group('Left', () {
      test('==', () {
        expect(Left<int>(1) == Either<int, Never>.left(1), isTrue);
        expect(Left<int>(1) == Left<num>(1), isFalse);
      });

      test('hashCode', () {
        expect(Left<int>(1).hashCode == Either<int, Never>.left(1).hashCode,
            isTrue);
        expect(Left<int>(1).hashCode == Left<num>(1).hashCode, isTrue);
      });

      test('toString', () {
        expect('Either.Left(1)', leftOf1.toString());
        expect('Either.Left([1, 2, 3])', Left([1, 2, 3]).toString());
      });
    });

    group('constructors', () {
      test('Either.left', () {
        expect(Either<int, Never>.left(1), leftOf1);
        expect(Either<int, Never>.left(1), isA<Left<int>>());
        expect(Either<int, Never>.left(1), isA<Either<int, Never>>());
        expect(Either<int, Never>.left(1), isA<Either<int, String>>());
        expect(Either<int, Never>.left(1), isA<Either<int, Object>>());
      });

      test('Either.right', () {
        expect(Either<Never, int>.right(1), rightOf1);
        expect(Either<Never, int>.right(1), isA<Right<int>>());
        expect(Either<Never, int>.right(1), isA<Either<Never, int>>());
        expect(Either<Never, int>.right(1), isA<Either<String, int>>());
        expect(Either<Never, int>.right(1), isA<Either<Object, int>>());
      });

      test('Either.catchError', () {
        // block does not throw
        expect(
          Either<Object, int>.catchError(takeOnlyError, () => 1),
          rightOf1,
        );

        // catch exception
        expect(
          Either<Object, String>.catchError(
              takeOnlyError, () => throw exception),
          Left<Object>(exception),
        );

        // ErrorMapper throws
        expect(
          () => Either<Object, String>.catchError(
            (e, s) => throw e,
            () => throw exception,
          ),
          throwsException,
        );

        // block throws [ControlError].
        expect(
          () => Either<Object, String>.catchError(
            takeOnlyError,
            () => throw MyControlError<Object>(),
          ),
          throwsA(isA<MyControlError>()),
        );
      });

      test('Either.binding', () {
        // single return
        expect(
          Either<Object, int>.binding((e) => 1),
          rightOf1,
        );

        // rethrow exception
        expect(
          () => Either<Object, int>.binding((e) => throw exception),
          throwsException,
        );

        // block throws [ControlError].
        expect(
          () => Either<Object, String>.binding(
            (e) => throw MyControlError<Object>(),
          ),
          throwsA(isA<NoSuchMethodError>()),
        );

        // 2 success bind
        expect(
          Either<Object, int>.binding((e) {
            final a = e.bind(Right(1));
            final b = e.bind(Right(2));
            return a + b;
          }),
          Right(3),
        );

        // 2 success either.bind
        expect(
          Either<Object, int>.binding((e) {
            final a = Either<Object, int>.right(1).bind(e);
            final b = Either<Object, int>.right(2).bind(e);
            return a + b;
          }),
          Right(3),
        );

        // 1 success bind + 1 failure bind
        expect(
          Either<Object, int>.binding((e) {
            final a = Either<Object, int>.right(1).bind(e);
            final b = Either<Object, int>.left(exception).bind(e);
            return a + b;
          }),
          Left<Object>(exception),
        );
      });
    });

    group('static construction', () {
      test('fromNullable', () {
        expect(
          Either.fromNullable<Object>(null),
          Left<void>(null),
        );
        expect(
          Either.fromNullable(2),
          Right(2),
        );
      });

      test('Either.futureBinding', () async {
        // single return
        await expectLater(
          Either.futureBinding<Object, int>((e) => 1),
          completion(rightOf1),
        );

        await expectLater(
          Either.futureBinding<Object, int>((e) async => 1),
          completion(rightOf1),
        );

        // rethrow exception
        await expectLater(
          Either.futureBinding<Object, int>((e) => throw exception),
          throwsException,
        );

        // rethrow exception from bindFuture
        await expectLater(
          Either.futureBinding<Object, int>(
            (e) => e.bindFuture(Future.error(exception)),
          ),
          throwsException,
        );

        // rethrow exception from bind
        await expectLater(
          Either.futureBinding<Object, int>(
            (e) => Future<Either<Object, int>>.error(exception).bind(e),
          ),
          throwsException,
        );

        // block throws [ControlError].
        expect(
          Either.futureBinding<Object, String>(
            (e) => throw MyControlError<Object>(),
          ),
          throwsA(isA<NoSuchMethodError>()),
        );

        // 2 success bind (sync) - without async modifier
        expect(
          Either.futureBinding<Object, int>((e) {
            final a = e.bind(Right(1));
            final b = e.bind(Right(2));
            return a + b;
          }),
          completion(Right(3)),
        );

        // 2 success bind (sync) - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a = e.bind(Right(1));
            final b = e.bind(Right(2));
            return a + b;
          }),
          completion(Right(3)),
        );

        // 2 success bind (async) - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a =
                await Future.sync(() => Either<Object, int>.right(1)).bind(e);
            final b = await e.bindFuture(Future.value(Right(2)));
            return a + b;
          }),
          completion(Right(3)),
        );

        // 1 success bind (sync) + 1 success bind (async) - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a =
                await Future.sync(() => Either<Object, int>.right(1)).bind(e);
            final b = e.bind(Right(2));
            return a + b;
          }),
          completion(Right(3)),
        );

        // 1 success bind (sync) + 1 success bind (async) - without async modifier
        expect(
          Either.futureBinding<Object, int>(
            (e) => Future.sync(() => Either<Object, int>.right(1))
                .bind(e)
                .then((a) => a + e.bind(Right(2))),
          ),
          completion(Right(3)),
        );

        // 2 success bind (async) either.bind - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a = await Future.value(Either<Object, int>.right(1)).bind(e);
            final b = await Future.value(Either<Object, int>.right(2)).bind(e);
            return a + b;
          }),
          completion(Right(3)),
        );

        // 1 success bind (async) + 1 failure bind (sync) - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a = await Future.delayed(
              const Duration(milliseconds: 100),
              () => Either<Object, int>.right(1),
            ).bind(e);

            final b = Either<Object, int>.left(exception).bind(e);

            return a + b;
          }),
          completion(Left<Object>(exception)),
        );

        // 1 success bind (async) + 1 failure bind (async) - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a = await Future.delayed(
              const Duration(milliseconds: 100),
              () => Either<Object, int>.right(1),
            ).bind(e);

            final b =
                await Future.sync(() => Either<Object, int>.left(exception))
                    .bind(e);

            return a + b;
          }),
          completion(Left<Object>(exception)),
        );
      });
    });

    test('extension .left() and .right()', () {
      expect(1.left(), leftOf1);
      expect(1.left(), Either<int, Never>.left(1));

      expect(1.right(), rightOf1);
      expect(1.right(), Either<Never, int>.right(1));
    });

    test('fold', () {
      expect(
        3,
        // ignore: unnecessary_cast
        (rightOf1 as Either<Object, int>).fold<int>(
          ifLeft: (v) => throw v,
          ifRight: (v) => v + 2,
        ),
      );

      expect(
        2,
        // ignore: unnecessary_cast
        (leftOf1 as Either<int, Object>).fold<int>(
          ifLeft: (v) => v + 1,
          ifRight: (v) => throw v,
        ),
      );
    });
  });
}
