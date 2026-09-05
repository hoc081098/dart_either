import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('getOrThrow', () {
    test('returns the Right value', () {
      expect(const Right<Object, int>(1).getOrThrow(), 1);
    });

    test('throws the identical Left value', () {
      final error = StateError('error');

      expect(
        () => Left<StateError, int>(error).getOrThrow(),
        throwsA(same(error)),
      );
    });

    test('supports widened variants', () {
      final error = StateError('error');
      final Either<Object, num> left = Left<StateError, Never>(error);
      const Either<Object, num> right = Right<Never, int>(1);

      expect(() => left.getOrThrow(), throwsA(same(error)));
      expect(right.getOrThrow(), 1);
    });
  });
}
