import 'package:test/test.dart';
import 'package:dart_either/dart_either.dart';

void main() {
  group('Either', () {
    group('constructors', () {
      test('Either.left', () {
        expect(Either.left(1), isA<Left<int>>());
      });
    });
  });
}
