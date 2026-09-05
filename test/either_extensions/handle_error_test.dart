import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('handleError', () {
    test('invokes the callback once for Left', () {
      var calls = 0;

      final result = const Left<String, int>('error').handleError((value) {
        calls++;
        return value.length;
      });

      expect(result, const Right<String, int>(5));
      expect(calls, 1);
    });

    test('preserves Right identity and skips the callback', () {
      const either = Right<String, int>(1);
      var calls = 0;

      final result = either.handleError((value) {
        calls++;
        return value.length;
      });

      expect(identical(result, either), isTrue);
      expect(calls, 0);
    });

    test('supports a widened Left receiver', () {
      const Either<String, num> either = Left<String, Never>('error');

      expect(
        either.handleError((value) => value.length + 0.5),
        const Right<String, num>(5.5),
      );
    });

    test('supports a widened Right receiver', () {
      const Either<String, num> either = Right<Never, int>(1);
      var calls = 0;

      final result = either.handleError((value) {
        calls++;
        return value.length + 0.5;
      });

      expect(identical(result, either), isTrue);
      expect(calls, 0);
    });

    test('propagates callback errors', () {
      final error = StateError('callback error');

      expect(
        () => const Left<String, int>('error').handleError(
          (_) => throw error,
        ),
        throwsA(same(error)),
      );
    });
  });
}
