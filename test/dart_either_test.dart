import 'package:test/test.dart';
import 'package:dart_either/dart_either.dart';

void main() {
  group('Either', () {
    const left = Left(1);
    const right = Right(1);

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
          Either.catchError((error, stackTrace) => error, () => 1),
          right,
        );
      });
    });
  });
}
