import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('handleErrorWith', () {
    test('handleErrorWith returns the callback Right for Left', () {
      var calls = 0;

      final result =
          const Left<String, int>('error').handleErrorWith<num>((value) {
        calls++;
        return Right<num, int>(value.length);
      });

      expect(result, const Right<num, int>(5));
      expect(calls, 1);
    });

    test('handleErrorWith returns the callback Left for Left', () {
      final result = const Left<String, int>('error').handleErrorWith<num>(
        (value) => Left<num, int>(value.length),
      );

      expect(result, const Left<num, int>(5));
    });

    test('handleErrorWith skips the callback for Right', () {
      var calls = 0;

      final result = const Right<String, int>(1).handleErrorWith<num>((value) {
        calls++;
        return Right<num, int>(value.length);
      });

      expect(result, const Right<num, int>(1));
      expect(calls, 0);
    });

    test('handleErrorWith supports a widened Left receiver', () {
      const Either<String, num> either = Left<String, Never>('error');

      expect(
        either.handleErrorWith<num>(
          (value) => Right<num, num>(value.length + 0.5),
        ),
        const Right<num, num>(5.5),
      );
    });

    test('handleErrorWith supports a widened Right receiver', () {
      const Either<String, num> either = Right<Never, int>(1);
      var calls = 0;

      final result = either.handleErrorWith<num>((value) {
        calls++;
        return Right<num, num>(value.length + 0.5);
      });

      expect(result, const Right<num, num>(1));
      expect(calls, 0);
    });

    test('handleErrorWith propagates callback errors', () {
      final error = StateError('callback error');

      expect(
        () => const Left<String, int>('error').handleErrorWith<Never>(
          (_) => throw error,
        ),
        throwsA(same(error)),
      );
    });
  });
}
