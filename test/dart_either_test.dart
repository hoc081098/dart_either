// ignore_for_file: unnecessary_cast

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

  const Either<int, Never> leftOf1 = Left(1);
  const Either<Never, int> rightOf1 = Right(1);

  final exception = Exception();
  final exceptionLeft = Left<Object, Never>(exception);

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
        expect(Right<Never, int>(1) == Either<Never, int>.right(1), isTrue);
        expect(Right<Never, int>(1) == Right<Never, num>(1), isTrue);
      });

      test('hashCode', () {
        expect(
            Right<Never, int>(1).hashCode ==
                Either<Never, int>.right(1).hashCode,
            isTrue);
        expect(Right<Never, int>(1).hashCode == Right<Never, num>(1).hashCode,
            isTrue);
      });

      test('toString', () {
        expect('Either.Right(1)', rightOf1.toString());
        expect('Either.Right([1, 2, 3])',
            Right<Never, List<int>>([1, 2, 3]).toString());
      });
    });

    group('Left', () {
      test('==', () {
        expect(Left<int, Never>(1) == Either<int, Never>.left(1), isTrue);
        expect(Left<int, Never>(1) == Left<num, Never>(1), isTrue);
      });

      test('hashCode', () {
        expect(
            Left<int, Never>(1).hashCode == Either<int, Never>.left(1).hashCode,
            isTrue);
        expect(Left<int, Never>(1).hashCode == Left<num, Never>(1).hashCode,
            isTrue);
      });

      test('toString', () {
        expect('Either.Left(1)', leftOf1.toString());
        expect('Either.Left([1, 2, 3])',
            Left<List<int>, Never>([1, 2, 3]).toString());
      });
    });

    group('constructors', () {
      test('Either.left', () {
        expect(Either<int, Never>.left(1), leftOf1);
        expect(Either<int, Never>.left(1), isA<Left<int, Never>>());
        expect(Either<int, Never>.left(1), isA<Either<int, Never>>());
        expect(Either<int, Never>.left(1), isA<Either<int, String>>());
        expect(Either<int, Never>.left(1), isA<Either<int, Object>>());
      });

      test('Either.right', () {
        expect(Either<Never, int>.right(1), rightOf1);
        expect(Either<Never, int>.right(1), isA<Right<Never, int>>());
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
          exceptionLeft,
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
          Right<Never, int>(3),
        );

        // 2 success either.bind
        expect(
          Either<Object, int>.binding((e) {
            final a = Either<Object, int>.right(1).bind(e);
            final b = Either<Object, int>.right(2).bind(e);
            return a + b;
          }),
          Right<Never, int>(3),
        );

        // 1 success bind + 1 failure bind
        expect(
          Either<Object, int>.binding((e) {
            final a = Either<Object, int>.right(1).bind(e);
            final b = Either<Object, int>.left(exception).bind(e);
            return a + b;
          }),
          exceptionLeft,
        );
      });
    });

    group('static construction', () {
      test('fromNullable', () {
        expect(
          Either.fromNullable<Object>(null),
          Left<void, Never>(null),
        );
        expect(
          Either.fromNullable(2),
          Right<Never, int>(2),
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
          completion(Right<Never, int>(3)),
        );

        // 2 success bind (sync) - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a = e.bind(Right(1));
            final b = e.bind(Right(2));
            return a + b;
          }),
          completion(Right<Never, int>(3)),
        );

        // 2 success bind (async) - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a =
                await Future.sync(() => Either<Object, int>.right(1)).bind(e);
            final b = await e.bindFuture(Future.value(Right(2)));
            return a + b;
          }),
          completion(Right<Never, int>(3)),
        );

        // 1 success bind (sync) + 1 success bind (async) - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a =
                await Future.sync(() => Either<Object, int>.right(1)).bind(e);
            final b = e.bind(Right(2));
            return a + b;
          }),
          completion(Right<Never, int>(3)),
        );

        // 1 success bind (sync) + 1 success bind (async) - without async modifier
        expect(
          Either.futureBinding<Object, int>(
            (e) => Future.sync(() => Either<Object, int>.right(1))
                .bind(e)
                .then((a) => a + e.bind(Right(2))),
          ),
          completion(Right<Never, int>(3)),
        );

        // 2 success bind (async) either.bind - with async modifier
        expect(
          Either.futureBinding<Object, int>((e) async {
            final a = await Future.value(Either<Object, int>.right(1)).bind(e);
            final b = await Future.value(Either<Object, int>.right(2)).bind(e);
            return a + b;
          }),
          completion(Right<Never, int>(3)),
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
          completion(exceptionLeft),
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
          completion(exceptionLeft),
        );
      });

      test('Either.catchFutureError', () async {
        // single return
        await expectLater(
          Either.catchFutureError<Object, int>(takeOnlyError, () => 1),
          completion(rightOf1),
        );

        await expectLater(
          Either.catchFutureError<Object, int>(takeOnlyError, () async => 1),
          completion(rightOf1),
        );

        await expectLater(
          Either.catchFutureError<Object, int>(takeOnlyError, () async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 1;
          }),
          completion(rightOf1),
        );

        await expectLater(
          Either.catchFutureError<Object, int>(
              takeOnlyError, () => Future.value(1)),
          completion(rightOf1),
        );

        // catch exception
        await expectLater(
          Either.catchFutureError<Object, int>(
              takeOnlyError, () => throw exception),
          completion(exceptionLeft),
        );

        await expectLater(
          Either.catchFutureError<Object, int>(
              takeOnlyError, () async => throw exception),
          completion(exceptionLeft),
        );
      });
    });

    test('extension .left() and .right()', () {
      expect(1.left<Never>(), leftOf1);
      expect(1.left<Never>(), Either<int, Never>.left(1));

      expect(1.right<Never>(), rightOf1);
      expect(1.right<Never>(), Either<Never, int>.right(1));
    });

    test('fold', () {
      expect(
        (rightOf1 as Either<Object, int>).fold<int>(
          ifLeft: (v) => throw v,
          ifRight: (v) => v + 2,
        ),
        3,
      );

      expect(
        (leftOf1 as Either<int, Object>).fold<int>(
          ifLeft: (v) => v + 1,
          ifRight: (v) => throw v,
        ),
        2,
      );
    });

    test('foldLeft', () {
      expect(
        (rightOf1 as Either<Object, int>).foldLeft<int>(0, (acc, e) => acc + e),
        1,
      );

      expect(
        (leftOf1 as Either<Object, int>).foldLeft<int>(0, (acc, e) => acc + e),
        0,
      );
    });

    test('swap', () {
      expect(rightOf1.swap(), leftOf1);
      expect(leftOf1.swap(), rightOf1);
    });

    test('map', () {
      expect(
        rightOf1.map((value) => value + 1),
        Right<Never, int>(2),
      );

      expect(
        (leftOf1 as Either<int, int>).map((value) => value + 1),
        leftOf1,
      );
    });

    test('mapLeft', () {
      expect(
        (rightOf1 as Either<int, int>).mapLeft((value) => value + 1),
        rightOf1,
      );

      expect(
        leftOf1.mapLeft((value) => value + 1),
        Left<int, Never>(2),
      );
    });

    test('flatMap', () {
      // right -> right
      expect(
        rightOf1.flatMap((value) => Right(value + 1)),
        Right<Never, int>(2),
      );

      // right -> left
      expect(
        1.right<int>().flatMap<bool>((value) => Either.left(2)),
        Left<int, Never>(2),
      );

      // left -> right
      expect(
        (leftOf1 as Either<int, int>).flatMap((value) => Right(value + 1)),
        leftOf1,
      );

      // left -> left
      expect(
        (leftOf1 as Either<int, int>)
            .flatMap((value) => Left<int, int>(value + 1)),
        leftOf1,
      );
    });

    test('bimap', () {
      expect(
        (rightOf1 as Either<int, int>)
            .bimap((value) => value + 1, (value) => value + 2),
        Right<Never, int>(3),
      );

      expect(
        (leftOf1 as Either<int, int>)
            .bimap((value) => value + 1, (value) => value + 2),
        Left<int, Never>(2),
      );
    });
  });
}
