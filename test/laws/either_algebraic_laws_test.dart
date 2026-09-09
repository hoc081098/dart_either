import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

typedef _Endomorphism<T> = T Function(T value);
typedef _EitherOperation = Either<String, int> Function(int value);

int _identityInt(int value) => value;

String _identityString(String value) => value;

Either<String, int> _pure(int value) => Either<String, int>.right(value);

void main() {
  const eithers = <Either<String, int>>[
    Left<String, int>('first'),
    Left<String, int>('second'),
    Right<String, int>(-2),
    Right<String, int>(0),
    Right<String, int>(3),
  ];
  const rightValues = <int>[-2, 0, 3];
  final rightOperations = <String, _Endomorphism<int>>{
    'increment': (value) => value + 1,
    'double': (value) => value * 2,
  };
  final leftOperations = <String, _Endomorphism<String>>{
    'append marker': (value) => '$value!',
    'decorate': (value) => '<$value>',
  };
  final flatMapOperations = <String, _EitherOperation>{
    'right increment': (value) => Either<String, int>.right(value + 1),
    'right square': (value) => Either<String, int>.right(value * value),
    'left always': (value) => Either<String, int>.left('rejected:$value'),
    'left for non-positive': (value) => value > 0
        ? Either<String, int>.right(value - 1)
        : Either<String, int>.left('non-positive:$value'),
  };

  group('Functor laws', () {
    test('identity', () {
      for (final either in eithers) {
        expect(
          either.map(_identityInt),
          either,
          reason: 'input: $either',
        );
      }
    });

    test('composition', () {
      for (final either in eithers) {
        for (final first in rightOperations.entries) {
          for (final second in rightOperations.entries) {
            expect(
              either.map(first.value).map(second.value),
              either.map((value) => second.value(first.value(value))),
              reason:
                  'input: $either, first: ${first.key}, second: ${second.key}',
            );
          }
        }
      }
    });
  });

  group('Monad laws', () {
    test('left identity', () {
      for (final value in rightValues) {
        for (final operation in flatMapOperations.entries) {
          expect(
            _pure(value).flatMap(operation.value),
            operation.value(value),
            reason: 'value: $value, operation: ${operation.key}',
          );
        }
      }
    });

    test('right identity', () {
      for (final either in eithers) {
        expect(
          either.flatMap(_pure),
          either,
          reason: 'input: $either',
        );
      }
    });

    test('associativity', () {
      for (final either in eithers) {
        for (final first in flatMapOperations.entries) {
          for (final second in flatMapOperations.entries) {
            expect(
              either.flatMap(first.value).flatMap(second.value),
              either.flatMap(
                (value) => first.value(value).flatMap(second.value),
              ),
              reason:
                  'input: $either, first: ${first.key}, second: ${second.key}',
            );
          }
        }
      }
    });
  });

  group('Bifunctor laws', () {
    test('identity', () {
      for (final either in eithers) {
        expect(
          either.bimap(
            leftOperation: _identityString,
            rightOperation: _identityInt,
          ),
          either,
          reason: 'input: $either',
        );
      }
    });

    test('composition', () {
      for (final either in eithers) {
        for (final firstLeft in leftOperations.entries) {
          for (final secondLeft in leftOperations.entries) {
            for (final firstRight in rightOperations.entries) {
              for (final secondRight in rightOperations.entries) {
                expect(
                  either
                      .bimap(
                        leftOperation: firstLeft.value,
                        rightOperation: firstRight.value,
                      )
                      .bimap(
                        leftOperation: secondLeft.value,
                        rightOperation: secondRight.value,
                      ),
                  either.bimap(
                    leftOperation: (value) =>
                        secondLeft.value(firstLeft.value(value)),
                    rightOperation: (value) =>
                        secondRight.value(firstRight.value(value)),
                  ),
                  reason: 'input: $either, left: ${firstLeft.key} then '
                      '${secondLeft.key}, right: ${firstRight.key} then '
                      '${secondRight.key}',
                );
              }
            }
          }
        }
      }
    });
  });

  group('Either API coherence', () {
    test('bimap(identity, rightMapper) matches map', () {
      for (final either in eithers) {
        for (final operation in rightOperations.entries) {
          expect(
            either.bimap(
              leftOperation: _identityString,
              rightOperation: operation.value,
            ),
            either.map(operation.value),
            reason: 'input: $either, right mapper: ${operation.key}',
          );
        }
      }
    });

    test('bimap(leftMapper, identity) matches mapLeft', () {
      for (final either in eithers) {
        for (final operation in leftOperations.entries) {
          expect(
            either.bimap(
              leftOperation: operation.value,
              rightOperation: _identityInt,
            ),
            either.mapLeft(operation.value),
            reason: 'input: $either, left mapper: ${operation.key}',
          );
        }
      }
    });

    test('swap is an involution', () {
      for (final either in eithers) {
        expect(
          either.swap().swap(),
          either,
          reason: 'input: $either',
        );
      }
    });

    test('swap commutes with bimap when mappers are exchanged', () {
      for (final either in eithers) {
        for (final leftOperation in leftOperations.entries) {
          for (final rightOperation in rightOperations.entries) {
            expect(
              either
                  .bimap(
                    leftOperation: leftOperation.value,
                    rightOperation: rightOperation.value,
                  )
                  .swap(),
              either.swap().bimap(
                    leftOperation: rightOperation.value,
                    rightOperation: leftOperation.value,
                  ),
              reason: 'input: $either, left mapper: ${leftOperation.key}, '
                  'right mapper: ${rightOperation.key}',
            );
          }
        }
      }
    });

    test('map matches flatMap followed by pure', () {
      for (final either in eithers) {
        for (final operation in rightOperations.entries) {
          expect(
            either.map(operation.value),
            either.flatMap((value) => _pure(operation.value(value))),
            reason: 'input: $either, right mapper: ${operation.key}',
          );
        }
      }
    });
  });
}
