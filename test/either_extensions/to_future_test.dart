import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('toFuture', () {
    test('completes with the Right value', () async {
      await expectLater(
        const Right<String, int>(1).toFuture(),
        completion(1),
      );
    });

    test('completes with the Left value as an error', () async {
      await expectLater(
        const Left<String, int>('error').toFuture(),
        throwsA('error'),
      );
    });

    test('supports widened variants', () async {
      const Either<Object, num> left = Left<String, Never>('error');
      const Either<Object, num> right = Right<Never, int>(1);

      await expectLater(left.toFuture(), throwsA('error'));
      await expectLater(right.toFuture(), completion(1));
    });
  });
}
