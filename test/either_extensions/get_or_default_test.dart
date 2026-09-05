import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('getOrDefault', () {
    test('returns the Right value', () {
      expect(const Right<String, int>(1).getOrDefault(2), 1);
    });

    test('returns the default for Left', () {
      expect(const Left<String, int>('error').getOrDefault(2), 2);
    });

    test('evaluates the default eagerly', () {
      var calls = 0;
      int makeDefault() {
        calls++;
        return 2;
      }

      expect(const Right<String, int>(1).getOrDefault(makeDefault()), 1);
      expect(calls, 1);
    });

    test('supports widened variants', () {
      const Either<String, num> left = Left<String, Never>('error');
      const Either<String, num> right = Right<Never, int>(1);

      expect(left.getOrDefault(2), 2);
      expect(right.getOrDefault(2.5), 1);
    });
  });
}
