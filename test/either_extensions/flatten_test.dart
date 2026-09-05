import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('flatten', () {
    test('returns an inner Right', () {
      expect(
        const Right<int, Either<int, int>>(Right<int, int>(2)).flatten(),
        const Right<int, int>(2),
      );
    });

    test('returns an inner Left', () {
      expect(
        const Right<int, Either<int, int>>(Left<int, int>(2)).flatten(),
        const Left<int, int>(2),
      );
    });

    test('returns an outer Left', () {
      expect(
        const Left<int, Either<int, int>>(1).flatten(),
        const Left<int, int>(1),
      );
    });

    test('supports widened nested variants', () {
      const Either<String, Either<String, num>> nestedRight =
          Right<Never, Either<Never, int>>(Right<Never, int>(1));

      const Either<String, Either<String, num>> nestedLeft =
          Right<Never, Either<String, Never>>(
        Left<String, Never>('inner'),
      );

      const Either<String, Either<String, num>> outerLeft =
          Left<String, Never>('outer');

      expect(nestedRight.flatten(), const Right<String, num>(1));
      expect(nestedLeft.flatten(), const Left<String, num>('inner'));
      expect(outerLeft.flatten(), const Left<String, num>('outer'));
    });
  });
}
