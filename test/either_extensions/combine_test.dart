import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  String combineLeft(String a, String b) => '$a,$b';
  num combineRight(num a, num b) => a + b;

  group('combine', () {
    test('combine combines two Right values', () {
      expect(
        const Right<String, num>(1).combine(
          const Right<String, num>(2),
          combineLeft: combineLeft,
          combineRight: combineRight,
        ),
        const Right<String, num>(3),
      );
    });

    test('combine combines two Left values', () {
      expect(
        const Left<String, num>('a').combine(
          const Left<String, num>('b'),
          combineLeft: combineLeft,
          combineRight: combineRight,
        ),
        const Left<String, num>('a,b'),
      );
    });

    test('combine returns the sole Left without invoking a combiner', () {
      var leftCalls = 0;
      var rightCalls = 0;

      final leftRight = const Left<String, num>('a').combine(
        const Right<String, num>(2),
        combineLeft: (a, b) {
          leftCalls++;
          return '$a,$b';
        },
        combineRight: (a, b) {
          rightCalls++;
          return a + b;
        },
      );
      expect(leftRight, const Left<String, num>('a'));
      expect(leftCalls, 0);
      expect(rightCalls, 0);

      final rightLeft = const Right<String, num>(2).combine(
        const Left<String, num>('a'),
        combineLeft: combineLeft,
        combineRight: combineRight,
      );
      expect(rightLeft, const Left<String, num>('a'));
    });

    test('combine supports widened receivers and operands', () {
      const Either<String, num> left = Left<String, Never>('error');
      const Either<String, num> intRight = Right<Never, int>(1);
      const Either<String, num> doubleRight = Right<Never, double>(2.5);

      const Either<num, num> intLeft = Left<int, Never>(1);
      const Either<num, num> doubleLeft = Left<double, Never>(2.5);

      var leftCalls = 0;
      var rightCalls = 0;

      expect(
        intRight.combine(
          doubleRight,
          combineLeft: (a, b) {
            leftCalls++;
            return '$a,$b';
          },
          combineRight: (a, b) {
            rightCalls++;
            return a + b;
          },
        ),
        const Right<String, num>(3.5),
      );
      expect(leftCalls, 0);
      expect(rightCalls, 1);

      leftCalls = 0;
      rightCalls = 0;
      expect(
        intRight.combine(
          left,
          combineLeft: (a, b) {
            leftCalls++;
            return '$a,$b';
          },
          combineRight: (a, b) {
            rightCalls++;
            return a + b;
          },
        ),
        same(left),
      );
      expect(leftCalls, 0);
      expect(rightCalls, 0);

      leftCalls = 0;
      rightCalls = 0;
      expect(
        left.combine(
          intRight,
          combineLeft: (a, b) {
            leftCalls++;
            return '$a,$b';
          },
          combineRight: (a, b) {
            rightCalls++;
            return a + b;
          },
        ),
        same(left),
      );
      expect(leftCalls, 0);
      expect(rightCalls, 0);

      leftCalls = 0;
      rightCalls = 0;
      expect(
        intLeft.combine(
          doubleLeft,
          combineLeft: (a, b) {
            leftCalls++;
            return a + b;
          },
          combineRight: (a, b) {
            rightCalls++;
            return a + b;
          },
        ),
        const Left<num, num>(3.5),
      );
      expect(leftCalls, 1);
      expect(rightCalls, 0);
    });
  });
}
