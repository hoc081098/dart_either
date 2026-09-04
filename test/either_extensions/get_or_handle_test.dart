import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('getOrHandle', () {
    test('getOrHandle invokes the fallback once for Left', () {
      var calls = 0;

      final result = const Left<String, int>('error').getOrHandle((value) {
        calls++;
        return value.length;
      });

      expect(result, 5);
      expect(calls, 1);
    });

    test('getOrHandle skips the fallback for Right', () {
      var calls = 0;

      final result = const Right<String, int>(1).getOrHandle((value) {
        calls++;
        return value.length;
      });

      expect(result, 1);
      expect(calls, 0);
    });

    test('getOrHandle supports a widened Left receiver', () {
      const Either<String, num> either = Left<String, Never>('error');

      expect(either.getOrHandle((value) => value.length + 0.5), 5.5);
    });

    test('getOrHandle supports a widened Right receiver', () {
      const Either<String, num> either = Right<Never, int>(1);
      var calls = 0;

      final result = either.getOrHandle((value) {
        calls++;
        return value.length + 0.5;
      });

      expect(result, 1);
      expect(calls, 0);
    });

    test('getOrHandle propagates fallback errors', () {
      final error = StateError('fallback error');

      expect(
        () => const Left<String, int>('error').getOrHandle(
          (_) => throw error,
        ),
        throwsA(same(error)),
      );
    });
  });
}
