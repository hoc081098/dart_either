// ignore_for_file: deprecated_member_use_from_same_package

import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  const Either<int, int> leftOf1 = Left(1);
  const Either<int, int> rightOf1 = Right(1);
  final exception = Exception();

  group('Deprecated aliases', () {
    test('tapLeft delegates to onLeft', () {
      Object? value;
      final rightTapped = rightOf1.tapLeft((v) => value = v);
      expect(rightTapped, rightOf1);
      expect(value, isNull);

      value = null;
      final leftTapped = leftOf1.tapLeft((v) => value = v);
      expect(leftTapped, leftOf1);
      expect(value, 1);
    });

    test('tap delegates to onRight', () {
      Object? value;
      final rightTapped = rightOf1.tap((v) => value = v);
      expect(rightTapped, rightOf1);
      expect(value, 1);

      value = null;
      final leftTapped = leftOf1.tap((v) => value = v);
      expect(leftTapped, leftOf1);
      expect(value, isNull);
    });

    test('exists delegates to isRightAnd', () {
      expect(rightOf1.exists((value) => value > 0), isTrue);
      expect(rightOf1.exists((value) => value > 1), isFalse);
      expect(leftOf1.exists((value) => value > 0), isFalse);
      expect(leftOf1.exists((value) => value > 1), isFalse);
    });

    test('getOrElse preserves lazy fallback behavior', () {
      var calls = 0;

      expect(
        rightOf1.getOrElse(() {
          calls += 1;
          return 2;
        }),
        1,
      );
      expect(calls, 0);

      expect(
        leftOf1.getOrElse(() {
          calls += 1;
          return 2;
        }),
        2,
      );
      expect(calls, 1);
    });

    test('orNull delegates to getOrNull', () {
      expect(rightOf1.orNull(), 1);
      expect(leftOf1.orNull(), isNull);
    });

    test('futureBinding delegates to bindingAsync', () async {
      await expectLater(
        Either.futureBinding<Object, int>(
          (effect) => effect.bind(Either<Object, int>.right(1)),
        ),
        completion(rightOf1),
      );
      await expectLater(
        Either.futureBinding<Object, int>((effect) async {
          await Future<void>.delayed(Duration.zero);
          return effect.bind(Either<Object, int>.left(exception));
        }),
        completion(Either<Object, int>.left(exception)),
      );
    });

    test('catchError delegates to tryCatch', () {
      expect(
        Either<Object, int>.catchError((e, s) => e, () => 1),
        rightOf1,
      );
      expect(
        Either<Object, int>.catchError((e, s) => e, () => throw exception),
        Left<Object, Never>(exception),
      );
    });

    test('catchFutureError delegates to tryCatchAsync', () async {
      await expectLater(
        Either.catchFutureError<Object, int>((e, s) => e, () => 1),
        completion(rightOf1),
      );
      await expectLater(
        Either.catchFutureError<Object, int>(
          (e, s) => e,
          () async => throw exception,
        ),
        completion(Left<Object, Never>(exception)),
      );
    });

    test('catchStreamError delegates to toEitherStream', () async {
      await expectLater(
        Either.catchStreamError<Object, int>(
          (e, s) => e,
          Stream<int>.error(exception),
        ),
        emitsInOrder(
          <Object>[
            Left<Object, Never>(exception),
            emitsDone,
          ],
        ),
      );
    });
  });
}
