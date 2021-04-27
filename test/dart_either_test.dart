import 'package:test/test.dart';
import 'package:dart_either/dart_either.dart';

void main() {
  final takeOnlyError = (Object error, StackTrace stackTrace) => error;

  group('Either', () {
    const left = Left(1);
    const right = Right(1);
    final exception = Exception();

    test('isLeft', () {
      expect(left.isLeft, isTrue);
      expect(right.isLeft, isFalse);
    });

    test('isRight', () {
      expect(left.isRight, isFalse);
      expect(right.isRight, isTrue);
    });

    group('constructors', () {
      test('Either.left', () {
        expect(Either.left(1), left);
        expect(Either.left(1), isA<Left<int>>());
        expect(Either.left(1), isA<Either<int, Never>>());
        expect(Either.left(1), isA<Either<int, String>>());
        expect(Either.left(1), isA<Either<int, Object>>());
      });

      test('Either.right', () {
        expect(Either.right(1), right);
        expect(Either.right(1), isA<Right<int>>());
        expect(Either.right(1), isA<Either<Never, int>>());
        expect(Either.right(1), isA<Either<String, int>>());
        expect(Either.right(1), isA<Either<Object, int>>());
      });

      test('Either.catchError', () {
        expect(
          Either<Object, int>.catchError(takeOnlyError, () => 1),
          right,
        );

        expect(
          Either<Object, String>.catchError(
              takeOnlyError, () => throw exception),
          Left<Object>(exception),
        );
      });

      test('Either.binding', () {
        // single return
        expect(
          Either<Object, int>.binding((e) => 1),
          right,
        );

        // rethrow exception
        expect(
          () => Either<Object, int>.binding((e) => throw exception),
          throwsException,
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

        // 2 success <<
        expect(
          Either<Object, int>.binding((e) {
            final a = e << Right(1);
            final b = e << Right(2);
            return a + b;
          }),
          Right(3),
        );

        // 1 success bind + 1 failure bind
        expect(
          Either<Object, int>.binding((e) {
            final a = e << Right(1);
            final b = e << Left(exception);
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
    });
  });
}
