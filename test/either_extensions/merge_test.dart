import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('merge', () {
    test('merge returns the Right value', () {
      expect(const Right<int, int>(2).merge(), 2);
    });

    test('merge returns the Left value', () {
      expect(const Left<int, int>(1).merge(), 1);
    });

    test('merge supports widened variants', () {
      const Either<num, num> left = Left<int, Never>(1);
      const Either<num, num> right = Right<Never, int>(2);

      expect(left.merge(), 1);
      expect(right.merge(), 2);
    });
  });
}
