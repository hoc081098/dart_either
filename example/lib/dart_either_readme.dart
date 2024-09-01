import 'package:dart_either/dart_either.dart';

void main() {
  /// Create an instance of [Right]
  final right = Either<String, int>.right(10);
  print(right); // Prints Either.Right(10)

  /// Create an instance of [Left]
  final left = Either<String, int>.left('none');
  print(left); // Prints Either.Left(none)

  /// Map the right value to a [String]
  final mapRight = right.map((a) => 'String: $a');
  print(mapRight); // Prints Either.Right(String: 10)

  /// Map the left value to a [int]
  final mapLeft = right.mapLeft((a) => a.length);
  print(mapLeft); // Prints Either.Right(10)

  /// Return [Left] if the function throws an error.
  /// Otherwise return [Right].
  final catchError = Either.catchError(
    (e, s) => 'Error: $e',
    () => int.parse('invalid'),
  );
  print(catchError);
  // Prints Either.Left(Error: FormatException: Invalid radix-10 number (at character 1)
  // invalid
  // ^
  // )

  /// Extract the value from [Either]
  final value1 = right.getOrElse(() => -1);
  final value2 = right.getOrHandle((l) => -1);
  print('$value1, $value2'); // Prints 10, 10

  /// Chain computations
  final flatMap = right.flatMap((a) => Either.right(a + 10));
  print(flatMap); // Prints Either.Right(20)

  /// Pattern matching
  right.fold(
    ifLeft: (l) => print('Left: $l'),
    ifRight: (r) => print('Right: $r'),
  ); // Prints Right(10)

  /// Convert to nullable value
  final nullableValue = right.orNull();
  print(nullableValue); // Prints 10
}
