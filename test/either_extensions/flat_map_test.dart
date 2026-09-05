import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('flatMap', () {
    test('invokes the callback once for Right', () {
      var calls = 0;

      final result = const Right<String, int>(1).flatMap<String>((value) {
        calls++;
        return Right<String, String>('value: $value');
      });

      expect(result, const Right<String, String>('value: 1'));
      expect(calls, 1);
    });

    test('returns a Left produced by the callback', () {
      expect(
        const Right<String, int>(1).flatMap<bool>(
          (value) => Left<String, bool>('error: $value'),
        ),
        const Left<String, bool>('error: 1'),
      );
    });

    test('skips the callback for Left', () {
      var calls = 0;

      final result = const Left<String, int>('error').flatMap<String>((value) {
        calls++;
        return Right<String, String>('value: $value');
      });

      expect(result, const Left<String, String>('error'));
      expect(calls, 0);
    });

    test('supports a widened Left receiver', () {
      const Either<String, num> either = Left<String, Never>('error');
      var calls = 0;

      final result = either.flatMap<String>((value) {
        calls++;
        return Right<String, String>('value: $value');
      });

      expect(result, const Left<String, String>('error'));
      expect(calls, 0);
    });

    test('supports a widened Right receiver', () {
      const Either<String, num> either = Right<Never, int>(1);
      var calls = 0;

      final result = either.flatMap<String>((value) {
        calls++;
        return Right<String, String>('value: $value');
      });

      expect(result, const Right<String, String>('value: 1'));
      expect(calls, 1);
    });

    test('propagates callback errors', () {
      final error = StateError('callback error');

      expect(
        () => const Right<String, int>(1).flatMap<Never>((_) => throw error),
        throwsA(same(error)),
      );
    });
  });
}
