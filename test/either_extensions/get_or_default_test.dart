import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('getOrDefault', () {
    test('getOrDefault returns the Right value', () {
      expect(const Right<String, int>(1).getOrDefault(2), 1);
    });

    test('getOrDefault returns the default for Left', () {
      expect(const Left<String, int>('error').getOrDefault(2), 2);
    });

    test('getOrDefault evaluates the default eagerly', () {
      var calls = 0;
      int makeDefault() {
        calls++;
        return 2;
      }

      expect(const Right<String, int>(1).getOrDefault(makeDefault()), 1);
      expect(calls, 1);
    });

    test('getOrDefault supports widened variants', () {
      const Either<String, int> left = Left<String, Never>('error');
      const Either<String, num> right = Right<Never, int>(1);

      expect(left.getOrDefault(2), 2);
      expect(right.getOrDefault(2.5), 1);
    });
  });
}
