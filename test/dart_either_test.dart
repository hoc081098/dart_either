import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:rxdart_ext/single.dart';
import 'package:test/test.dart';

Object takeOnlyError(Object error, StackTrace stackTrace) => error;

class _RegisteredFatalException implements Exception {}

final class _RegisteredFatalSubtype extends _RegisteredFatalException {}

void main() {
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

      group('Either.tryCatch', () {
        test('action does not throw', () {
          expect(
            Either<Object, int>.tryCatch(
              action: () => 1,
              errorMapper: takeOnlyError,
            ),
            rightOf1,
          );
        });

        test('catch exception', () {
          expect(
            Either<Object, String>.tryCatch(
              action: () => throw exception,
              errorMapper: takeOnlyError,
            ),
            exceptionLeft,
          );
        });

        test('ErrorMapper throws', () {
          expect(
            () => Either<Object, String>.tryCatch(
              action: () => throw exception,
              errorMapper: (e, s) => throw e,
            ),
            throwsException,
          );
        });

        test('rethrows ControlError to the owning binding scope', () {
          final result = Either<String, int>.binding((effect) {
            Either<String, int>.tryCatch(
              action: () => effect.raise('raised'),
              errorMapper: (e, s) => 'mapped',
            );
            return 42;
          });

          expect(result, const Left<String, Never>('raised'));
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

      group('Either.bindingAsync', () {
        test('single return', () async {
          // single return
          await expectLater(
            Either.bindingAsync<Object, int>((e) => 1),
            completion(rightOf1),
          );

          await expectLater(
            Either.bindingAsync<Object, int>((e) async => 1),
            completion(rightOf1),
          );
        });

        test('rethrow exception', () async {
          // rethrow exception
          await expectLater(
            Either.bindingAsync<Object, int>((e) => throw exception),
            throwsException,
          );
        });

        test('rethrow error from bindFuture with an error Future', () async {
          // rethrow exception from bindFuture
          await expectLater(
            Either.bindingAsync<Object, int>(
              (e) => e.bindFuture(Future.error(exception)),
            ),
            throwsException,
          );
        });

        test('rethrow error from bind with an error Future', () async {
          // rethrow exception from bind
          await expectLater(
            Either.bindingAsync<Object, int>(
              (e) => Future<Either<Object, int>>.error(exception).bind(e),
            ),
            throwsException,
          );
        });

        // test('block throws [ControlError].', () {
        //   // block throws [ControlError].
        //   expect(
        //     Either.bindingAsync<Object, String>(
        //       (e) => throw MyControlError<Object>(),
        //     ),
        //     throwsA(isA<NoSuchMethodError>()),
        //   );
        // });

        test('2 success bind (sync) - without async modifier', () {
          // 2 success bind (sync) - without async modifier
          expect(
            Either.bindingAsync<Object, int>((e) {
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
            Either.bindingAsync<Object, int>((e) async {
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
            Either.bindingAsync<Object, int>((e) async {
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
              Either.bindingAsync<Object, int>((e) async {
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
              Either.bindingAsync<Object, int>(
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
            Either.bindingAsync<Object, int>((e) async {
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
              Either.bindingAsync<Object, int>((e) async {
                final a = await Future<Either<Object, int>>.delayed(
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
              Either.bindingAsync<Object, int>((e) async {
                final a = await Future<Either<Object, int>>.delayed(
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
            Either.bindingAsync<Object, String>((e) {
              final a = Either<Object, int>.right(1).bind(e);
              final b = Either<Object, String>.right('2').bind(e);
              return a.toString() + b;
            }),
            completion(Right<Never, String>('12')),
          );
        });
      });

      group('Either.tryCatchAsync', () {
        test('single return', () async {
          await expectLater(
            Either.tryCatchAsync<Object, int>(
              action: () => 1,
              errorMapper: takeOnlyError,
            ),
            completion(rightOf1),
          );

          await expectLater(
            Either.tryCatchAsync<Object, int>(
              action: () async => 1,
              errorMapper: takeOnlyError,
            ),
            completion(rightOf1),
          );

          await expectLater(
            Either.tryCatchAsync<Object, int>(
              action: () => Future.value(1),
              errorMapper: takeOnlyError,
            ),
            completion(rightOf1),
          );
        });

        test('single return with delay', () async {
          await expectLater(
            Either.tryCatchAsync<Object, int>(
              action: () async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return 1;
              },
              errorMapper: takeOnlyError,
            ),
            completion(rightOf1),
          );
        });

        test('catch exception', () async {
          await expectLater(
            Either.tryCatchAsync<Object, int>(
              action: () => throw exception,
              errorMapper: takeOnlyError,
            ),
            completion(exceptionLeft),
          );

          await expectLater(
            Either.tryCatchAsync<Object, int>(
              action: () async => throw exception,
              errorMapper: takeOnlyError,
            ),
            completion(exceptionLeft),
          );
        });

        test('catch error from future', () async {
          final errorFuture = Future<int>.error(exception);
          await expectLater(
            Either.tryCatchAsync(
              action: () => errorFuture,
              errorMapper: takeOnlyError,
            ),
            completion(exceptionLeft),
          );
          await expectLater(
            errorFuture.toEitherFuture(takeOnlyError),
            completion(exceptionLeft),
          );
        });

        test('rethrows ControlError to the owning bindingAsync scope',
            () async {
          final result = await Either.bindingAsync<String, int>((effect) async {
            await Either.tryCatchAsync<String, int>(
              action: () => effect.raise('raised'),
              errorMapper: (e, s) => 'mapped',
            );
            return 42;
          });

          expect(result, const Left<String, Never>('raised'));
        });
      });

      group('Stream.toEitherStream', () {
        test('single value', () async {
          await expectLater(
            Stream.value(1).toEitherStream(takeOnlyError),
            emitsInOrder(<Object>[Right<Never, int>(1), emitsDone]),
          );
          await expectLater(
            Single.value(1).toEitherStream(takeOnlyError),
            emitsInOrder(<Object>[Right<Never, int>(1), emitsDone]),
          );
        });

        test('single error', () async {
          await expectLater(
            Stream<int>.error(exception).toEitherStream(takeOnlyError),
            emitsInOrder(<Object>[exceptionLeft, emitsDone]),
          );
          await expectLater(
            Single<int>.error(exception).toEitherStream(takeOnlyError),
            emitsInOrder(<Object>[exceptionLeft, emitsDone]),
          );
        });

        test('one value + one error', () async {
          await expectLater(
            Rx.concat<int>([
              Single.value(1),
              Single.error(exception),
            ]).toEitherStream(takeOnlyError),
            emitsInOrder(<Object>[
              Right<Never, int>(1),
              exceptionLeft,
              emitsDone,
            ]),
          );
        });

        test('value + error + value + error', () async {
          await expectLater(
            Rx.concat<int>([
              Single.value(1),
              Single.error(exception),
              Stream.value(2),
              Single.error('Error'),
            ]).toEitherStream(takeOnlyError),
            emitsInOrder(<Object>[
              Right<Never, int>(1),
              exceptionLeft,
              Right<Object, int>(2),
              Left<String, Never>('Error'),
              emitsDone,
            ]),
          );
        });

        test('rethrows ControlError to the owning bindingAsync scope',
            () async {
          final result = await Either.bindingAsync<String, int>((effect) async {
            await Stream<int>.fromFuture(
              Future<int>.sync(() => effect.raise('raised')),
            ).toEitherStream<String>((e, s) => 'mapped').drain<void>();

            return 1;
          });

          expect(result, const Left<String, Never>('raised'));
        });
      });

      group('Either.registerFatalError', () {
        test('preserves registered types, their subtypes, and the stack trace',
            () async {
          final fatalSubType = _RegisteredFatalSubtype();
          final originalStackTrace = StackTrace.fromString('fatal origin');

          var mapperCalls = 0;
          Object errorMapper(Object error, StackTrace stackTrace) {
            mapperCalls += 1;
            return error;
          }

          Either.registerFatalError<_RegisteredFatalException>();
          Either.registerFatalError<_RegisteredFatalException>();

          expect(
            () => Either<Object, int>.tryCatch(
              action: () => throw fatalSubType,
              errorMapper: errorMapper,
            ),
            throwsA(same(fatalSubType)),
          );

          await expectLater(
            Either.tryCatchAsync<Object, int>(
              action: () async => throw fatalSubType,
              errorMapper: errorMapper,
            ),
            throwsA(same(fatalSubType)),
          );

          try {
            await Future<int>.error(
              fatalSubType,
              originalStackTrace,
            ).toEitherFuture(errorMapper);
            fail('Expected the registered fatal error to propagate');
          } catch (error, stackTrace) {
            expect(error, same(fatalSubType));
            expect(stackTrace.toString(), originalStackTrace.toString());
          }

          await expectLater(
            Stream<int>.error(fatalSubType).toEitherStream(errorMapper),
            emitsInOrder(<Object>[emitsError(same(fatalSubType)), emitsDone]),
          );

          expect(mapperCalls, 0);
        });
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

      group('Either.parSequenceN', () {
        test('right path with concurrency limit', () async {
          final values = <int>[];
          final delays = [100, 50, 200]; // Different delays to test concurrency

          final result = await Either.parSequenceN<String, int>(
            functions: delays.map(
              (delay) => () async {
                await Future<void>.delayed(Duration(milliseconds: delay));
                values.add(delay);
                return Either<String, int>.right(delay);
              },
            ),
            maxConcurrent: 2,
          );

          expect(result, Right<String, BuiltList<int>>(delays.build()));
          expect(values, containsAll(delays)); // All executed
        });

        test('right path without concurrency limit', () async {
          final values = <int>[];
          final delays = [100, 50, 200];

          final result = await Either.parSequenceN<String, int>(
            functions: delays.map(
              (delay) => () async {
                await Future<void>.delayed(Duration(milliseconds: delay));
                values.add(delay);
                return Either<String, int>.right(delay);
              },
            ),
            maxConcurrent: null, // no limit
          );

          expect(result, Right<String, BuiltList<int>>(delays.build()));
          expect(values, containsAll(delays));
        });

        test('left path short-circuits', () async {
          final values = <int>[];
          final items = [0, 1, 2]; // Use indices directly
          const anchor = 1;

          final result = await Either.parSequenceN<String, int>(
            functions: items.map(
              (index) => () async {
                await Future<void>.delayed(
                    Duration(milliseconds: (index + 1) * 50));
                values.add(index);
                return index < anchor
                    ? Either<String, int>.right(index)
                    : Either<String, int>.left('error$index');
              },
            ),
            maxConcurrent: 2,
          );

          expect(result, Left<String, BuiltList<int>>('error$anchor'));
          expect(values.length, anchor + 1); // Only up to the error
        });

        test('concurrency actually limited', () async {
          final activeCount = <int>[];
          final delays = [200, 200, 200]; // Same delay to test concurrency

          final result = await Either.parSequenceN<String, int>(
            functions: delays.map(
              (delay) => () async {
                activeCount.add(1);
                await Future<void>.delayed(Duration(milliseconds: delay));
                activeCount.add(-1);
                return Either<String, int>.right(delay);
              },
            ),
            maxConcurrent: 2, // max 2 concurrent
          );

          expect(result.isRight, isTrue);
          expect(activeCount.where((x) => x == 1).length, 3); // 3 starts
          expect(activeCount.where((x) => x == -1).length, 3); // 3 ends
          expect(
            activeCount,
            [1, 1, -1, 1, -1, -1],
          ); // No more than 2 active at once
        });
      });

      group('Either.parTraverseN', () {
        test('right path with concurrency limit', () async {
          final values = <int>[];
          final ids = [1, 2, 3];
          final factor = 10;

          final result = await Either.parTraverseN<String, int, int>(
            values: ids,
            mapper: (id) => () async {
              await Future<void>.delayed(Duration(milliseconds: id * 50));
              values.add(id);
              return Either<String, int>.right(id * factor);
            },
            maxConcurrent: 2,
          );

          final expectedValues = [
            for (final v in ids) v * factor,
          ].build();
          expect(result, Right<String, BuiltList<int>>(expectedValues));
          expect(values, containsAll(ids));
        });

        test('left path short-circuits', () async {
          final values = <int>[];
          final ids = [1, 2, 3];
          const anchor = 2;
          final factor = 10;

          final result = await Either.parTraverseN<String, int, int>(
            values: ids,
            mapper: (id) => () async {
              await Future<void>.delayed(Duration(milliseconds: id * 50));
              values.add(id);
              return id < anchor
                  ? Either<String, int>.right(id * factor)
                  : Either<String, int>.left('error$id');
            },
            maxConcurrent: 2,
          );

          expect(result, Left<String, BuiltList<int>>('error$anchor'));
          expect(values.length, anchor); // Only up to the error
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

    test('onLeft', () {
      Object? value;
      expect(
        rightOf1.onLeft((v) => value = v),
        rightOf1,
      );
      expect(value, isNull);

      value = null;
      expect(
        leftOf1.onLeft((v) => value = v),
        leftOf1,
      );
      expect(value, 1);
    });

    test('onRight', () {
      Object? value;
      expect(
        rightOf1.onRight((v) => value = v),
        rightOf1,
      );
      expect(value, 1);

      value = null;
      expect(
        leftOf1.onRight((v) => value = v),
        leftOf1,
      );
      expect(value, isNull);
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

    test('combine', () {
      expect(
        Right<String, int>(1).combine(
          Right<String, int>(2),
          combineLeft: (a, b) => '$a,$b',
          combineRight: (a, b) => a + b,
        ),
        Right<String, int>(3),
      );

      expect(
        Left<String, int>('a').combine(
          Left<String, int>('b'),
          combineLeft: (a, b) => '$a,$b',
          combineRight: (a, b) => a + b,
        ),
        Left<String, int>('a,b'),
      );

      expect(
        Left<String, int>('a').combine(
          Right<String, int>(2),
          combineLeft: (a, b) => '$a,$b',
          combineRight: (a, b) => a + b,
        ),
        Left<String, int>('a'),
      );

      expect(
        Right<String, int>(2).combine(
          Left<String, int>('a'),
          combineLeft: (a, b) => '$a,$b',
          combineRight: (a, b) => a + b,
        ),
        Left<String, int>('a'),
      );
    });

    test('combine only invokes relevant combiner', () {
      var leftCalls = 0;
      var rightCalls = 0;

      final result = Left<String, int>('a').combine(
        Right<String, int>(2),
        combineLeft: (a, b) {
          leftCalls += 1;
          return '$a,$b';
        },
        combineRight: (a, b) {
          rightCalls += 1;
          return a + b;
        },
      );

      expect(result, Left<String, int>('a'));
      expect(leftCalls, 0);
      expect(rightCalls, 0);
    });

    test('flatten', () {
      expect(
        const Right<int, Either<int, int>>(Right<int, int>(2)).flatten(),
        const Right<int, int>(2),
      );

      expect(
        const Right<int, Either<int, int>>(Left<int, int>(2)).flatten(),
        const Left<int, int>(2),
      );

      expect(
        const Left<int, Either<int, int>>(1).flatten(),
        const Left<int, int>(1),
      );
    });

    test('merge', () {
      expect(const Right<int, int>(2).merge(), 2);
      expect(const Left<int, int>(1).merge(), 1);
    });

    test('isRightAnd', () {
      expect(rightOf1.isRightAnd((value) => value > 0), isTrue);
      expect(rightOf1.isRightAnd((value) => value > 1), isFalse);

      expect(
        leftOf1.isRightAnd((value) => value > 0),
        isFalse,
      );
      expect(
        leftOf1.isRightAnd((value) => value > 1),
        isFalse,
      );
    });

    group('isLeftAnd', () {
      test('returns the predicate result for Left', () {
        expect(leftOf1.isLeftAnd((value) => value > 0), isTrue);
        expect(leftOf1.isLeftAnd((value) => value > 1), isFalse);
      });

      test('returns false without invoking the predicate for Right', () {
        var calls = 0;

        expect(
          rightOf1.isLeftAnd((_) {
            calls += 1;
            return true;
          }),
          isFalse,
        );
        expect(calls, 0);
      });
    });

    test('all', () {
      expect(rightOf1.all((value) => value > 0), isTrue);
      expect(rightOf1.all((value) => value > 1), isFalse);

      expect(
        leftOf1.all((value) => value > 0),
        isTrue,
      );
      expect(
        leftOf1.all((value) => value > 1),
        isTrue,
      );
    });

    test('getOrDefault', () {
      expect(rightOf1.getOrDefault(2), 1);
      expect(leftOf1.getOrDefault(2), 2);
    });

    test('getOrDefault is eager', () {
      var called = 0;
      int makeDefault() {
        called += 1;
        return 2;
      }

      expect(rightOf1.getOrDefault(makeDefault()), 1);
      expect(called, 1);

      called = 0;
      expect(leftOf1.getOrDefault(makeDefault()), 2);
      expect(called, 1);
    });

    group('covariance safety', () {
      test('basic inspection supports widened variants', () {
        const Either<Object, num> widenedLeft = Left<String, Never>('error');
        const Either<Object, num> widenedRight = Right<Never, int>(1);

        expect(widenedLeft.isLeft, isTrue);
        expect(widenedLeft.isRight, isFalse);
        expect(widenedRight.isLeft, isFalse);
        expect(widenedRight.isRight, isTrue);

        var leftCalls = 0;
        var rightCalls = 0;

        expect(
          widenedLeft.fold<String>(
            ifLeft: (value) {
              leftCalls += 1;
              return 'left:$value';
            },
            ifRight: (value) {
              rightCalls += 1;
              return 'right:$value';
            },
          ),
          'left:error',
        );
        expect(leftCalls, 1);
        expect(rightCalls, 0);

        leftCalls = 0;
        rightCalls = 0;
        expect(
          widenedRight.fold<String>(
            ifLeft: (value) {
              leftCalls += 1;
              return 'left:$value';
            },
            ifRight: (value) {
              rightCalls += 1;
              return 'right:$value';
            },
          ),
          'right:1',
        );
        expect(leftCalls, 0);
        expect(rightCalls, 1);
      });

      test('foldLeft and swap support widened variants', () {
        const Either<Object, num> widenedLeft = Left<String, Never>('error');
        const Either<Object, num> widenedRight = Right<Never, int>(1);
        var operationCalls = 0;

        // ------------ foldLeft ------------
        expect(
          widenedLeft.foldLeft<num>(0.5, (acc, value) {
            operationCalls += 1;
            return acc + value;
          }),
          0.5,
        );
        expect(operationCalls, 0);

        expect(
          widenedRight.foldLeft<num>(0.5, (acc, value) {
            operationCalls += 1;
            return acc + value;
          }),
          1.5,
        );
        expect(operationCalls, 1);

        // ------------ swap ------------
        expect(widenedLeft.swap(), Right<num, Object>('error'));
        expect(widenedRight.swap(), Left<num, Object>(1));
      });

      test('side effects and mappings support widened variants', () {
        const Either<Object, num> widenedLeft = Left<String, Never>('error');
        const Either<Object, num> widenedRight = Right<Never, int>(1);
        var leftCalls = 0;
        var rightCalls = 0;

        // ------------ onLeft and onRight ------------
        expect(
          widenedLeft.onLeft((value) {
            leftCalls += 1;
            expect(value, 'error');
          }),
          widenedLeft,
        );
        expect(
          widenedLeft.onRight((_) => rightCalls += 1),
          widenedLeft,
        );
        expect(leftCalls, 1);
        expect(rightCalls, 0);

        leftCalls = rightCalls = 0;
        expect(
          widenedRight.onLeft((_) => leftCalls += 1),
          widenedRight,
        );
        expect(
          widenedRight.onRight((value) {
            rightCalls += 1;
            expect(value, 1);
          }),
          widenedRight,
        );
        expect(leftCalls, 0);
        expect(rightCalls, 1);

        // ------------ map and mapLeft ------------
        expect(
          widenedLeft.map((value) => 'right:$value'),
          Left<Object, String>('error'),
        );
        expect(
          widenedRight.map((value) => 'right:$value'),
          Right<Object, String>('right:1'),
        );
        expect(
          widenedLeft.mapLeft((value) => 'left:$value'),
          Left<String, num>('left:error'),
        );
        expect(
          widenedRight.mapLeft((value) => 'left:$value'),
          Right<String, num>(1),
        );

        // ------------ bimap ------------
        leftCalls = rightCalls = 0;
        expect(
          widenedLeft.bimap(
            leftOperation: (value) {
              leftCalls += 1;
              return 'left:$value';
            },
            rightOperation: (value) {
              rightCalls += 1;
              return 'right:$value';
            },
          ),
          Left<String, String>('left:error'),
        );
        expect(leftCalls, 1);
        expect(rightCalls, 0);

        leftCalls = rightCalls = 0;
        expect(
          widenedRight.bimap(
            leftOperation: (value) {
              leftCalls += 1;
              return 'left:$value';
            },
            rightOperation: (value) {
              rightCalls += 1;
              return 'right:$value';
            },
          ),
          Right<String, String>('right:1'),
        );
        expect(leftCalls, 0);
        expect(rightCalls, 1);
      });

      test('side predicates support widened variants', () {
        const Either<Object, int> widenedLeft = Left<String, Never>('error');
        const Either<String, num> widenedRight = Right<Never, int>(1);

        expect(widenedLeft.isLeftAnd((value) => value == 'error'), isTrue);
        expect(widenedLeft.isRightAnd((value) => value > 0), isFalse);
        expect(widenedRight.isRightAnd((value) => value > 0), isTrue);
        expect(widenedRight.isLeftAnd((value) => value.isNotEmpty), isFalse);
      });

      test('all and nullable extraction support widened variants', () {
        const Either<Object, num> widenedLeft = Left<String, Never>('error');
        const Either<Object, num> widenedRight = Right<Never, int>(1);
        var predicateCalls = 0;

        // ------------ all ------------
        expect(
          widenedLeft.all((_) {
            predicateCalls += 1;
            return false;
          }),
          isTrue,
        );
        expect(predicateCalls, 0);

        expect(
          widenedRight.all((value) {
            predicateCalls += 1;
            return value > 0;
          }),
          isTrue,
        );
        expect(predicateCalls, 1);

        // ------------ getOrNull and leftOrNull ------------
        expect(widenedLeft.getOrNull(), isNull);
        expect(widenedLeft.leftOrNull(), 'error');
        expect(widenedRight.getOrNull(), 1);
        expect(widenedRight.leftOrNull(), isNull);

        // ------------ findOrNull ------------
        predicateCalls = 0;
        expect(
          widenedLeft.findOrNull((_) {
            predicateCalls += 1;
            return true;
          }),
          isNull,
        );
        expect(predicateCalls, 0);

        expect(
          widenedRight.findOrNull((value) {
            predicateCalls += 1;
            return value > 0;
          }),
          1,
        );
        expect(predicateCalls, 1);
      });

      test('when supports widened variants', () {
        const Either<Object, num> widenedLeft = Left<String, Never>('error');
        const Either<Object, num> widenedRight = Right<Never, int>(1);
        var leftCalls = 0;
        var rightCalls = 0;

        String resolve(Either<Object, num> either) {
          leftCalls = 0;
          rightCalls = 0;

          return either.when(
            ifLeft: (left) {
              leftCalls += 1;
              return 'left:${left.value}';
            },
            ifRight: (right) {
              rightCalls += 1;
              return 'right:${right.value}';
            },
          );
        }

        expect(resolve(widenedLeft), 'left:error');
        expect(leftCalls, 1);
        expect(rightCalls, 0);

        expect(resolve(widenedRight), 'right:1');
        expect(leftCalls, 0);
        expect(rightCalls, 1);
      });

      test('redeem operations support widened variants', () {
        const Either<Object, num> widenedLeft = Left<String, Never>('error');
        const Either<Object, num> widenedRight = Right<Never, int>(1);
        var leftCalls = 0;
        var rightCalls = 0;

        // ------------ redeem ------------
        Either<Object, String> redeem(Either<Object, num> either) {
          leftCalls = 0;
          rightCalls = 0;

          return either.redeem(
            leftOperation: (value) {
              leftCalls += 1;
              return 'left:$value';
            },
            rightOperation: (value) {
              rightCalls += 1;
              return 'right:$value';
            },
          );
        }

        expect(redeem(widenedLeft), Right<Object, String>('left:error'));
        expect(leftCalls, 1);
        expect(rightCalls, 0);

        expect(redeem(widenedRight), Right<Object, String>('right:1'));
        expect(leftCalls, 0);
        expect(rightCalls, 1);

        // ------------ redeemWith ------------
        Either<String, String> redeemWith(Either<Object, num> either) {
          leftCalls = 0;
          rightCalls = 0;

          return either.redeemWith(
            leftOperation: (value) {
              leftCalls += 1;
              return 'left:$value'.right<String>();
            },
            rightOperation: (value) {
              rightCalls += 1;
              return 'right:$value'.right<String>();
            },
          );
        }

        expect(redeemWith(widenedLeft), Right<String, String>('left:error'));
        expect(leftCalls, 1);
        expect(rightCalls, 0);

        expect(redeemWith(widenedRight), Right<String, String>('right:1'));
        expect(leftCalls, 0);
        expect(rightCalls, 1);
      });

      test('getOrDefault supports widened variants', () {
        const Either<String, int> widenedLeft = Left<String, Never>('error');
        const Either<String, num> widenedRight = Right<Never, int>(1);

        expect(widenedLeft.getOrDefault(2), 2);
        expect(widenedRight.getOrDefault(2.5), 1);
      });

      test('combine supports widened receivers and operands', () {
        const Either<String, num> widenedLeft = Left<String, Never>('error');
        const Either<String, num> widenedIntRight = Right<Never, int>(1);
        const Either<String, num> widenedDoubleRight =
            Right<Never, double>(2.5);
        const Either<num, num> widenedIntLeft = Left<int, Never>(1);
        const Either<num, num> widenedDoubleLeft = Left<double, Never>(2.5);

        String combineLeft(String a, String b) => '$a,$b';
        num combineRight(num a, num b) => a + b;

        var widenedLeftCalls = 0;
        var widenedRightCalls = 0;
        num combineWidenedLeft(num a, num b) {
          widenedLeftCalls += 1;
          return a + b;
        }

        num combineWidenedRight(num a, num b) {
          widenedRightCalls += 1;
          return a + b;
        }

        expect(
          widenedIntRight.combine(
            widenedLeft,
            combineLeft: combineLeft,
            combineRight: combineRight,
          ),
          widenedLeft,
        );
        expect(
          widenedLeft.combine(
            widenedIntRight,
            combineLeft: combineLeft,
            combineRight: combineRight,
          ),
          widenedLeft,
        );
        expect(
          widenedIntRight.combine(
            widenedDoubleRight,
            combineLeft: combineLeft,
            combineRight: combineRight,
          ),
          Right<String, num>(3.5),
        );

        widenedLeftCalls = 0;
        widenedRightCalls = 0;
        expect(
          widenedIntLeft.combine(
            widenedDoubleLeft,
            combineLeft: combineWidenedLeft,
            combineRight: combineWidenedRight,
          ),
          Left<num, num>(3.5),
        );
        expect(widenedLeftCalls, 1);
        expect(widenedRightCalls, 0);

        widenedLeftCalls = 0;
        widenedRightCalls = 0;
        expect(
          widenedDoubleLeft.combine(
            widenedIntLeft,
            combineLeft: combineWidenedLeft,
            combineRight: combineWidenedRight,
          ),
          Left<num, num>(3.5),
        );
        expect(widenedLeftCalls, 1);
        expect(widenedRightCalls, 0);
      });

      test('flatten supports widened nested variants', () {
        const Either<String, Either<String, int>> widenedNestedRight =
            Right<Never, Either<Never, int>>(
          Right<Never, int>(1),
        );
        const Either<String, Either<String, int>> widenedNestedLeft =
            Right<Never, Either<String, Never>>(
          Left<String, Never>('inner'),
        );
        const Either<String, Either<String, int>> widenedOuterLeft =
            Left<String, Never>('outer');

        expect(widenedNestedRight.flatten(), Right<String, int>(1));
        expect(widenedNestedLeft.flatten(), Left<String, int>('inner'));
        expect(widenedOuterLeft.flatten(), Left<String, int>('outer'));
      });

      test('merge supports widened variants', () {
        const Either<num, num> widenedLeft = Left<int, Never>(1);
        const Either<num, num> widenedRight = Right<Never, int>(2);

        expect(widenedLeft.merge(), 1);
        expect(widenedRight.merge(), 2);
      });
    });

    test('getOrNull', () {
      expect(rightOf1.getOrNull(), 1);
      expect(leftOf1.getOrNull(), isNull);
    });

    test('leftOrNull', () {
      expect(rightOf1.leftOrNull(), isNull);
      expect(leftOf1.leftOrNull(), 1);
    });

    test('getOrHandle', () {
      expect(rightOf1.getOrHandle((l) => l + 1), 1);
      expect(leftOf1.getOrHandle((l) => l + 1), 2);

      var called = 0;
      rightOf1.getOrHandle((_) {
        called += 1;
        return 2;
      });
      expect(called, 0);

      leftOf1.getOrHandle((_) {
        called += 1;
        return 2;
      });
      expect(called, 1);
    });

    test('findOrNull', () {
      expect(leftOf1.findOrNull((value) => value > 0), isNull);
      expect(leftOf1.findOrNull((value) => value > 2), isNull);

      expect(rightOf1.findOrNull((value) => value > 0), 1);
      expect(rightOf1.findOrNull((value) => value > 2), isNull);
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

    test('handleErrorWith', () {
      var calls = 0;

      expect(
        leftOf1.handleErrorWith<String>((value) {
          calls += 1;
          return value.right();
        }),
        Right<String, int>(1),
      );
      expect(calls, 1);

      calls = 0;
      expect(
        leftOf1.handleErrorWith<String>((value) => value.toString().left()),
        Left<String, int>('1'),
      );

      final handledRight = rightOf1.handleErrorWith<String>((value) {
        calls += 1;
        return value.right();
      });
      expect(
        handledRight,
        rightOf1,
      );
      expect(calls, 0);

      expect(
        rightOf1.handleErrorWith<String>((value) => value.toString().left()),
        rightOf1,
      );
    });

    test('handleError', () {
      final handledRight = rightOf1.handleError((value) => throw value);

      expect(handledRight, rightOf1);
      expect(identical(handledRight, rightOf1), isTrue);
      expect(leftOf1.handleError((value) => value + 1), Right<int, int>(2));
    });

    test('redeem', () {
      final inferredResults = [
        rightOf1.redeem(
          leftOperation: (v) => v.toString(),
          rightOperation: (v) => v.toString(),
        ),
      ];
      inferredResults.add(const Left<int, String>(2));

      expect(
        inferredResults,
        const <Either<int, String>>[
          Right<int, String>('1'),
          Left<int, String>(2),
        ],
      );

      expect(
        rightOf1.redeem(
          leftOperation: (v) => v.toString(),
          rightOperation: (v) => v.toString(),
        ),
        Right<String, String>('1'),
      );

      expect(
        leftOf1.redeem(
          leftOperation: (v) => v.toString(),
          rightOperation: (v) => v.toString(),
        ),
        Right<String, String>('1'),
      );
    });

    test('redeemWith', () {
      expect(
        rightOf1.redeemWith(
          leftOperation: (v) => throw v,
          rightOperation: (v) => v.toString().right<String>(),
        ),
        Right<String, String>('1'),
      );
      expect(
        rightOf1.redeemWith(
          leftOperation: (v) => throw v,
          rightOperation: (v) => v.toString().left<String>(),
        ),
        Left<String, String>('1'),
      );

      expect(
        leftOf1.redeemWith(
          leftOperation: (v) => v.toString().right<String>(),
          rightOperation: (v) => throw v,
        ),
        Right<String, String>('1'),
      );
      expect(
        leftOf1.redeemWith(
          leftOperation: (v) => v.toString().left<String>(),
          rightOperation: (v) => throw v,
        ),
        Left<String, String>('1'),
      );
    });

    test('recovery operations do not catch selected callback exceptions', () {
      final error = StateError('callback failed');

      expect(
        () => leftOf1.handleErrorWith<String>((_) => throw error),
        throwsA(same(error)),
      );
      expect(
        () => leftOf1.handleError((_) => throw error),
        throwsA(same(error)),
      );
      expect(
        () => rightOf1.redeem<String>(
          leftOperation: (value) => value.toString(),
          rightOperation: (_) => throw error,
        ),
        throwsA(same(error)),
      );
      expect(
        () => rightOf1.redeemWith<String, String>(
          leftOperation: (value) => value.toString().left<String>(),
          rightOperation: (_) => throw error,
        ),
        throwsA(same(error)),
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

    group('EitherEffect.raise', () {
      test('raise short-circuits binding with Left in Either.binding', () {
        expect(
          Either<String, int>.binding((effect) {
            effect.raise('error');
          }),
          Left<String, int>('error'),
        );
      });

      test('code after raise is unreachable in Either.binding', () {
        var reached = false;
        Either<String, int>.binding((effect) {
          effect.raise('error');
          reached = true; // ignore: dead_code
          return 0;
        });
        expect(reached, isFalse);
      });

      test('raise short-circuits after successful binds in Either.binding', () {
        expect(
          Either<String, int>.binding((effect) {
            final a = effect.bind(Either<String, int>.right(1));
            final b = effect.bind(Either<String, int>.right(2));
            effect.raise('stop');
            return a + b; // ignore: dead_code
          }),
          Left<String, int>('stop'),
        );
      });

      test('conditional raise returns Right when condition not met', () {
        expect(
          Either<String, int>.binding((effect) {
            final value = effect.bind(Either<String, int>.right(42));
            if (value < 0) effect.raise('negative');
            return value;
          }),
          Right<String, int>(42),
        );
      });

      test('conditional raise returns Left when condition met', () {
        expect(
          Either<String, int>.binding((effect) {
            final value = effect.bind(Either<String, int>.right(-1));
            if (value < 0) effect.raise('negative');
            return value;
          }),
          Left<String, int>('negative'),
        );
      });

      test(
        'raise short-circuits binding with Left in Either.bindingAsync',
        () async {
          await expectLater(
            Either.bindingAsync<String, int>((effect) async {
              effect.raise('error');
            }),
            completion(Left<String, int>('error')),
          );
        },
      );

      test('code after raise is unreachable in Either.bindingAsync', () async {
        var reached = false;
        await Either.bindingAsync<String, int>((effect) async {
          effect.raise('error');
          reached = true; // ignore: dead_code
          return 0;
        });
        expect(reached, isFalse);
      });

      test(
        'raise short-circuits after async bind in Either.bindingAsync',
        () async {
          await expectLater(
            Either.bindingAsync<String, int>((effect) async {
              final a = await effect
                  .bindFuture(Future.value(Either<String, int>.right(1)));
              effect.raise('stop');
              return a; // ignore: dead_code
            }),
            completion(Left<String, int>('stop')),
          );
        },
      );

      test('raise return type is Never — usable as expression', () {
        // raise returns Never, so it can be used as the else branch of ?:
        expect(
          Either<String, int>.binding((effect) {
            final int? nullable = null;
            return nullable ?? effect.raise('missing');
          }),
          Left<String, int>('missing'),
        );
      });
    });

    group('Future<Either<L, R>>.thenFlatMapEither', () {
      //
      // Right
      //

      test('Future completes with a Right value, map to a Right value', () {
        expect(
          Future.value(rightOf1).thenFlatMapEither((v) => (v + 1).right()),
          completion(Right<int, int>(2)),
        );
      });

      test(
        'Future completes with a Right value, map to a Future of Right value',
        () {
          expect(
            Future.value(rightOf1)
                .thenFlatMapEither((v) async => (v + 1).right()),
            completion(Right<int, int>(2)),
          );
        },
      );

      test(
        'Future completes with a Right value, throw exception',
        () {
          expect(
            Future.value(rightOf1)
                .thenFlatMapEither<String>((v) => throw exception),
            throwsException,
          );
        },
      );

      test(
        'Future completes with a Right value, return a error Future',
        () {
          expect(
            Future.value(rightOf1)
                .thenFlatMapEither<String>((v) async => throw exception),
            throwsException,
          );

          expect(
            Future.value(rightOf1)
                .thenFlatMapEither<String>((v) => Future.error(exception)),
            throwsException,
          );
        },
      );

      //
      // Left
      //

      test('Future completes with a Left value, map to a Right value', () {
        expect(
          Future.value(leftOf1).thenFlatMapEither((v) => (v + 1).right()),
          completion(leftOf1),
        );
      });

      test(
        'Future completes with a Left value, map to a Future of Right value',
        () {
          expect(
            Future.value(leftOf1)
                .thenFlatMapEither((v) async => (v + 1).right()),
            completion(leftOf1),
          );
        },
      );

      test(
        'Future completes with a Left value, throw exception',
        () {
          expect(
            Future.value(leftOf1)
                .thenFlatMapEither<String>((v) => throw exception),
            completion(leftOf1),
          );
        },
      );

      test(
        'Future completes with a Left value, return a error Future',
        () {
          expect(
            Future.value(leftOf1)
                .thenFlatMapEither<String>((v) async => throw exception),
            completion(leftOf1),
          );

          expect(
            Future.value(leftOf1)
                .thenFlatMapEither<String>((v) => Future.error(exception)),
            completion(leftOf1),
          );
        },
      );
    });

    group('Future<Either<L, R>>.thenMapEither', () {
      //
      // Right
      //

      test('Future completes with a Right value, map to a value', () {
        expect(
          Future.value(rightOf1).thenMapEither((v) => v + 1),
          completion(Right<int, int>(2)),
        );
      });

      test(
        'Future completes with a Right value, map to a Future completes with a value',
        () {
          expect(
            Future.value(rightOf1).thenMapEither((v) async => v + 1),
            completion(Right<int, int>(2)),
          );
        },
      );

      test(
        'Future completes with a Right value, throw exception',
        () {
          expect(
            Future.value(rightOf1)
                .thenMapEither<String>((v) => throw exception),
            throwsException,
          );
        },
      );

      test(
        'Future completes with a Right value, return a error Future',
        () {
          expect(
            Future.value(rightOf1)
                .thenMapEither<String>((v) async => throw exception),
            throwsException,
          );

          expect(
            Future.value(rightOf1)
                .thenMapEither<String>((v) => Future.error(exception)),
            throwsException,
          );
        },
      );

      //
      // Left
      //

      test('Future completes with a Left value, map to a value', () {
        expect(
          Future.value(leftOf1).thenMapEither((v) => v + 1),
          completion(leftOf1),
        );
      });

      test(
        'Future completes with a Left value, map to a Future of Right value',
        () {
          expect(
            Future.value(leftOf1).thenMapEither((v) async => v + 1),
            completion(leftOf1),
          );
        },
      );

      test(
        'Future completes with a Left value, throw exception',
        () {
          expect(
            Future.value(leftOf1).thenMapEither<String>((v) => throw exception),
            completion(leftOf1),
          );
        },
      );

      test(
        'Future completes with a Left value, return a error Future',
        () {
          expect(
            Future.value(leftOf1)
                .thenMapEither<String>((v) async => throw exception),
            completion(leftOf1),
          );

          expect(
            Future.value(leftOf1)
                .thenMapEither<String>((v) => Future.error(exception)),
            completion(leftOf1),
          );
        },
      );
    });
  });
}
