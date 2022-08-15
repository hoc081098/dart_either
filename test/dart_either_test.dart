import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:rxdart_ext/single.dart';
import 'package:test/test.dart';
import 'semaphore_test.dart' as semaphore_test;

Object takeOnlyError(Object error, StackTrace stackTrace) => error;

class MyControlError<L> implements ControlError<L> {
  @override
  StackTrace? get stackTrace => null;
}

void main() {
  semaphore_test.main();

  const Either<int, int> leftOf1 = Left(1);
  const Either<int, int> rightOf1 = Right(1);

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

      group('Either.catchError', () {
        test('block does not throw', () {
          // block does not throw
          expect(
            Either<Object, int>.catchError(takeOnlyError, () => 1),
            rightOf1,
          );
        });

        test('catch exception', () {
          // catch exception
          expect(
            Either<Object, String>.catchError(
                takeOnlyError, () => throw exception),
            exceptionLeft,
          );
        });

        test('ErrorMapper throws', () {
          // ErrorMapper throws
          expect(
            () => Either<Object, String>.catchError(
              (e, s) => throw e,
              () => throw exception,
            ),
            throwsException,
          );
        });

        test('block throws [ControlError].', () {
          // block throws [ControlError].
          expect(
            () => Either<Object, String>.catchError(
              takeOnlyError,
              () => throw MyControlError<Object>(),
            ),
            throwsA(isA<MyControlError>()),
          );
        });
      });

      group('Either.binding', () {
        test('single return', () {
          // single return
          expect(
            Either<Object, int>.binding((e) => 1),
            rightOf1,
          );
        });

        test('rethrow exception', () {
          // rethrow exception
          expect(
            () => Either<Object, int>.binding((e) => throw exception),
            throwsException,
          );
        });

        test('block throws [ControlError].', () {
          // block throws [ControlError].
          expect(
            () => Either<Object, String>.binding(
              (e) => throw MyControlError<Object>(),
            ),
            throwsA(isA<NoSuchMethodError>()),
          );
        });

        test('2 success bind', () {
          // 2 success bind
          expect(
            Either<Object, int>.binding((e) {
              final a = e.bind(Right(1));
              final b = e.bind(Right(2));
              return a + b;
            }),
            Right<Never, int>(3),
          );
        });

        test('2 success either.bind', () {
          // 2 success either.bind
          expect(
            Either<Object, int>.binding((e) {
              final a = Either<Object, int>.right(1).bind(e);
              final b = Either<Object, int>.right(2).bind(e);
              return a + b;
            }),
            Right<Never, int>(3),
          );
        });

        test('2 success either.bind with difference types.', () {
          // 2 success either.bind with difference types.
          expect(
            Either<Object, String>.binding((e) {
              final a = Either<Object, int>.right(1).bind(e);
              final b = Either<Object, String>.right('2').bind(e);
              return a.toString() + b;
            }),
            Right<Never, String>('12'),
          );
        });

        test('1 success bind + 1 failure bind', () {
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

      group('Either.futureBinding', () {
        test('single return', () async {
          // single return
          await expectLater(
            Either.futureBinding<Object, int>((e) => 1),
            completion(rightOf1),
          );

          await expectLater(
            Either.futureBinding<Object, int>((e) async => 1),
            completion(rightOf1),
          );
        });

        test('rethrow exception', () async {
          // rethrow exception
          await expectLater(
            Either.futureBinding<Object, int>((e) => throw exception),
            throwsException,
          );
        });

        test('rethrow error from bindFuture with an error Future', () async {
          // rethrow exception from bindFuture
          await expectLater(
            Either.futureBinding<Object, int>(
              (e) => e.bindFuture(Future.error(exception)),
            ),
            throwsException,
          );
        });

        test('rethrow error from bind with an error Future', () async {
          // rethrow exception from bind
          await expectLater(
            Either.futureBinding<Object, int>(
              (e) => Future<Either<Object, int>>.error(exception).bind(e),
            ),
            throwsException,
          );
        });

        test('block throws [ControlError].', () {
          // block throws [ControlError].
          expect(
            Either.futureBinding<Object, String>(
              (e) => throw MyControlError<Object>(),
            ),
            throwsA(isA<NoSuchMethodError>()),
          );
        });

        test('2 success bind (sync) - without async modifier', () {
          // 2 success bind (sync) - without async modifier
          expect(
            Either.futureBinding<Object, int>((e) {
              final a = e.bind(Right(1));
              final b = e.bind(Right(2));
              return a + b;
            }),
            completion(Right<Never, int>(3)),
          );
        });

        test('2 success bind (sync) - with async modifier', () {
          // 2 success bind (sync) - with async modifier
          expect(
            Either.futureBinding<Object, int>((e) async {
              final a = e.bind(Right(1));
              final b = e.bind(Right(2));
              return a + b;
            }),
            completion(Right<Never, int>(3)),
          );
        });

        test('2 success bind (async) - with async modifier', () {
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
        });

        test(
          '1 success bind (sync) + 1 success bind (async) - with async modifier',
          () {
            // 1 success bind (sync) + 1 success bind (async) - with async modifier
            expect(
              Either.futureBinding<Object, int>((e) async {
                final a = await Future.sync(() => Either<Object, int>.right(1))
                    .bind(e);
                final b = e.bind(Right(2));
                return a + b;
              }),
              completion(Right<Never, int>(3)),
            );
          },
        );

        test(
          '1 success bind (sync) + 1 success bind (async) - without async modifier',
          () {
            // 1 success bind (sync) + 1 success bind (async) - without async modifier
            expect(
              Either.futureBinding<Object, int>(
                (e) => Future.sync(() => Either<Object, int>.right(1))
                    .bind(e)
                    .then((a) => a + e.bind(Right(2))),
              ),
              completion(Right<Never, int>(3)),
            );
          },
        );

        test('2 success bind (async) either.bind - with async modifier', () {
          // 2 success bind (async) either.bind - with async modifier
          expect(
            Either.futureBinding<Object, int>((e) async {
              final a =
                  await Future.value(Either<Object, int>.right(1)).bind(e);
              final b =
                  await Future.value(Either<Object, int>.right(2)).bind(e);
              return a + b;
            }),
            completion(Right<Never, int>(3)),
          );
        });

        test(
          '1 success bind (async) + 1 failure bind (sync) - with async modifier',
          () {
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
          },
        );

        test(
          '1 success bind (async) + 1 failure bind (async) - with async modifier',
          () {
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
          },
        );

        test('2 success either.bind (sync) with difference types.', () {
          // 2 success either.bind (sync) with difference types.
          expect(
            Either.futureBinding<Object, String>((e) {
              final a = Either<Object, int>.right(1).bind(e);
              final b = Either<Object, String>.right('2').bind(e);
              return a.toString() + b;
            }),
            completion(Right<Never, String>('12')),
          );
        });
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

        final errorFuture = Future<int>.error(exception);
        await expectLater(
          Either.catchFutureError(takeOnlyError, () => errorFuture),
          completion(exceptionLeft),
        );
        await expectLater(
          errorFuture.toEitherFuture(takeOnlyError),
          completion(exceptionLeft),
        );
      });

      test('Either.catchStreamError', () async {
        // single value
        await expectLater(
          Either.catchStreamError(takeOnlyError, Stream.value(1)),
          emitsInOrder(<Object>[Right<Never, int>(1), emitsDone]),
        );
        await expectLater(
          Either.catchStreamError(takeOnlyError, Single.value(1)),
          emitsInOrder(<Object>[Right<Never, int>(1), emitsDone]),
        );
        await expectLater(
          Single.value(1).toEitherStream(takeOnlyError),
          emitsInOrder(<Object>[Right<Never, int>(1), emitsDone]),
        );

        // single error
        await expectLater(
          Either.catchStreamError(takeOnlyError, Stream<int>.error(exception)),
          emitsInOrder(<Object>[exceptionLeft, emitsDone]),
        );
        await expectLater(
          Either.catchStreamError(takeOnlyError, Single<int>.error(exception)),
          emitsInOrder(<Object>[exceptionLeft, emitsDone]),
        );
        await expectLater(
          Single<int>.error(exception).toEitherStream(takeOnlyError),
          emitsInOrder(<Object>[exceptionLeft, emitsDone]),
        );

        // one value + one error
        await expectLater(
          Either.catchStreamError(
            takeOnlyError,
            Rx.concat<int>([
              Single.value(1),
              Single.error(exception),
            ]),
          ),
          emitsInOrder(<Object>[
            Right<Never, int>(1),
            exceptionLeft,
            emitsDone,
          ]),
        );

        // value + error + value + error
        await expectLater(
          Either.catchStreamError(
            takeOnlyError,
            Rx.concat<int>([
              Single.value(1),
              Single.error(exception),
              Stream.value(2),
              Single.error('Error'),
            ]),
          ),
          emitsInOrder(<Object>[
            Right<Never, int>(1),
            exceptionLeft,
            Right<Object, int>(2),
            Left<String, Never>('Error'),
            emitsDone,
          ]),
        );
      });

      group('Either.sequence', () {
        test('right path', () {
          final List<int> range =
              Iterable.generate(20000, (i) => i).toList(growable: false);
          final values = <int>[];

          expect(
            Either.sequence(
              range.map((e) {
                values.add(e);
                return Either<int, int>.right(e);
              }),
            ),
            Right<int, BuiltList<int>>(range.build()),
          );
          expect(values, range);
        });

        test('left path', () {
          final values = <int>[];
          const anchor = 100;

          expect(
            Either.sequence(
              Iterable.generate(20000, (i) => i).map((e) {
                values.add(e);

                return e < anchor
                    ? Either<int, int>.right(e)
                    : Either<int, int>.left(e);
              }),
            ),
            Left<int, BuiltList<int>>(anchor),
          );

          expect(values.length, anchor + 1);
          expect(values, Iterable.generate(anchor + 1, (i) => i).toList());
        });
      });

      group('Either.traverse', () {
        test('right path', () {
          final List<int> range =
              Iterable.generate(20000, (i) => i).toList(growable: false);
          final values = <int>[];

          expect(
            Either.traverse(
              range,
              (int e) {
                values.add(e);
                return Either<int, int>.right(e);
              },
            ),
            Right<int, BuiltList<int>>(range.build()),
          );
          expect(values, range);
        });

        test('left path', () {
          final values = <int>[];
          const anchor = 100;

          expect(
            Either.traverse(Iterable.generate(20000, (i) => i), (int e) {
              values.add(e);

              return e < anchor
                  ? Either<int, int>.right(e)
                  : Either<int, int>.left(e);
            }),
            Left<int, BuiltList<int>>(anchor),
          );

          expect(values.length, anchor + 1);
          expect(values, Iterable.generate(anchor + 1, (i) => i).toList());
        });
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
        rightOf1.fold<int>(
          ifLeft: (v) => throw v,
          ifRight: (v) => v + 2,
        ),
        3,
      );

      expect(
        leftOf1.fold<int>(
          ifLeft: (v) => v + 1,
          ifRight: (v) => throw v,
        ),
        2,
      );
    });

    test('foldLeft', () {
      expect(
        rightOf1.foldLeft<int>(0, (acc, e) => acc + e),
        1,
      );

      expect(
        leftOf1.foldLeft<int>(0, (acc, e) => acc + e),
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
        leftOf1.map((value) => value + 1),
        leftOf1,
      );
    });

    test('mapLeft', () {
      expect(
        rightOf1.mapLeft((value) => value + 1),
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
        leftOf1.flatMap((value) => Right(value + 1)),
        leftOf1,
      );

      // left -> left
      expect(
        leftOf1.flatMap((value) => Left<int, int>(value + 1)),
        leftOf1,
      );
    });

    test('bimap', () {
      expect(
        rightOf1.bimap(
          leftOperation: (value) => value + 1,
          rightOperation: (value) => value + 2,
        ),
        Right<Never, int>(3),
      );

      expect(
        leftOf1.bimap(
          leftOperation: (value) => value + 1,
          rightOperation: (value) => value + 2,
        ),
        Left<int, Never>(2),
      );
    });

    test('exists', () {
      expect(rightOf1.exists((value) => value > 0), isTrue);
      expect(rightOf1.exists((value) => value > 1), isFalse);

      expect(
        leftOf1.exists((value) => value > 0),
        isFalse,
      );
      expect(
        leftOf1.exists((value) => value > 1),
        isFalse,
      );
    });

    test('getOrElse', () {
      expect(rightOf1.getOrElse(() => 2), 1);
      expect(leftOf1.getOrElse(() => 2), 2);
    });

    test('orNull', () {
      expect(rightOf1.orNull(), 1);
      expect(leftOf1.orNull(), isNull);
    });

    test('getOrHandle', () {
      expect(rightOf1.getOrHandle((l) => l + 1), 1);
      expect(leftOf1.getOrHandle((l) => l + 1), 2);
    });

    test('when', () {
      expect(
        rightOf1.when(ifLeft: (value) => null, ifRight: (value) => value),
        rightOf1,
      );
      expect(
        leftOf1.when(ifLeft: (value) => null, ifRight: (value) => value),
        isNull,
      );

      expect(
        leftOf1.when(ifLeft: (value) => value, ifRight: (value) => null),
        leftOf1,
      );
      expect(
        rightOf1.when(ifLeft: (value) => value, ifRight: (value) => null),
        isNull,
      );
    });

    test('toFuture', () async {
      await expectLater(rightOf1.toFuture(), completion(1));
      await expectLater(leftOf1.toFuture(), throwsA(1));
    });

    test('getOrThrow', () {
      expect(rightOf1.getOrThrow(), 1);
      expect(() => leftOf1.getOrThrow(), throwsA(1));
    });

    test('EitherEffect.ensure', () {
      expect(
        Either<String, int>.binding((effect) {
          effect.ensure(<Object>[].isEmpty, () => 'Error'); // passed
          return 1;
        }),
        Right<String, int>(1),
      );

      expect(
        Either<String, int>.binding((effect) {
          effect.ensure([0].isEmpty, () => 'Error'); // failed
          return 1;
        }),
        Left<String, int>('Error'),
      );
    });

    test('EitherEffect.ensureNotNull', () {
      expect(
        Either<String, int>.binding((effect) {
          final int v = effect.ensureNotNull(2, () => 'Error'); // passed
          return v + 1;
        }),
        Right<String, int>(3),
      );

      expect(
        Either<String, int>.binding((effect) {
          final int v = effect.ensureNotNull(null, () => 'Error'); // failed
          return v + 1;
        }),
        Left<String, int>('Error'),
      );
    });
  });
}
