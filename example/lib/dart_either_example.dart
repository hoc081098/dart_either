import 'package:dart_either/dart_either.dart';

Either<String, int> parseQuantity(String input) {
  final int? quantity = int.tryParse(input);
  return quantity == null
      ? Either.left('Quantity must be an integer')
      : Either.right(quantity);
}

Either<String, int> calculateOrderTotal({
  required String? quantityInput,
  required int unitPrice,
  required int availableStock,
}) =>
    Either.binding((effect) {
      // 1) Require the nullable input.
      final String input = effect.ensureNotNull(
        quantityInput,
        () => 'Quantity is required',
      );

      // 2) Bind an Either, propagating its Left automatically.
      final int quantity = effect.bind(parseQuantity(input));

      // 3) Enforce a value-level invariant.
      effect.ensure(quantity > 0, () => 'Quantity must be positive');

      // 4) Raise a domain error without constructing a Left to bind.
      if (quantity > availableStock) {
        effect.raise('Only $availableStock items are in stock');
      }

      // 5) A normal return becomes Right(total).
      return quantity * unitPrice;
    });

void main() {
  // ---------------------------------------------------------------------------
  // 1) Creation
  // ---------------------------------------------------------------------------

  /// Create an instance of [Right]
  final Either<String, int> right = Either.right(10);
  print(right); // Prints Either.Right(10)

  /// Create an instance of [Left]
  final Either<String, int> left = Either.left('none');
  print(left); // Prints Either.Left(none)

  /// Map the right value to a [String]
  final Either<String, String> mapRight = right.map((a) => 'String: $a');
  print(mapRight); // Prints Either.Right(String: 10)

  /// Map the left value to a [int]
  final Either<int, int> mapLeft = right.mapLeft((a) => a.length);
  print(mapLeft); // Prints Either.Right(10)

  /// Return [Left] if the function throws an error.
  /// Otherwise return [Right].
  final Either<String, int> tryCatchResult = Either.tryCatch(
    action: () => int.parse('invalid'),
    errorMapper: (e, s) => 'Error: $e',
  );
  print(tryCatchResult);
  // Prints Either.Left(Error: FormatException: Invalid radix-10 number (at character 1)
  // invalid
  // ^
  // )

  // ---------------------------------------------------------------------------
  // 2) Operations: extraction, transformation, composition
  // ---------------------------------------------------------------------------

  /// Extract values from [Either]
  final int value1 = right.getOrDefault(-1);
  final int value2 = right.getOrHandle((l) => -1);
  final int? nullableValue = right.getOrNull();
  final String? leftValue = left.leftOrNull();
  print('$value1, $value2'); // Prints 10, 10
  print(leftValue); // Prints none
  print(nullableValue); // Prints 10

  /// Match the value on either side with a predicate
  print(right.isRightAnd((value) => value > 0)); // Prints true
  print(left.isLeftAnd((value) => value == 'none')); // Prints true

  /// Transform and compose
  final Either<String, int> flatMap =
      right.flatMap((a) => Either.right(a + 10));
  print(flatMap); // Prints Either.Right(20)

  /// Combine two Either values
  final Either<String, int> combined = right.combine(
    Either<String, int>.right(5),
    combineLeft: (a, b) => '$a,$b',
    combineRight: (a, b) => a + b,
  );
  print(combined); // Prints Either.Right(15)

  final Either<String, int> flattened =
      Either<String, Either<String, int>>.right(
    Either<String, int>.right(10),
  ).flatten();
  print(flattened); // Prints Either.Right(10)

  final int merged = Either<int, int>.right(10).merge();
  print(merged); // Prints 10

  // ---------------------------------------------------------------------------
  // 3) Binding: compose Either operations and raise domain errors
  // ---------------------------------------------------------------------------

  /// A successful binding unwraps [Right] values and returns the final result
  /// as a [Right].
  final Either<String, int> successfulOrder = calculateOrderTotal(
    quantityInput: '3',
    unitPrice: 20,
    availableStock: 10,
  );
  print(successfulOrder); // Prints Either.Right(60)

  /// Binding a [Left] from [parseQuantity] short-circuits the computation.
  final Either<String, int> invalidQuantity = calculateOrderTotal(
    quantityInput: 'three',
    unitPrice: 20,
    availableStock: 10,
  );
  print(invalidQuantity); // Prints Either.Left(Quantity must be an integer)

  /// `raise` short-circuits with an existing domain error without constructing
  /// a [Left] solely to bind it.
  final Either<String, int> insufficientStock = calculateOrderTotal(
    quantityInput: '12',
    unitPrice: 20,
    availableStock: 10,
  );
  print(insufficientStock); // Prints Either.Left(Only 10 items are in stock)

  // ---------------------------------------------------------------------------
  // 4) Pattern matching
  // ---------------------------------------------------------------------------

  /// Pattern matching
  right.fold(
    ifLeft: (l) => print('Left value: $l'),
    ifRight: (r) => print('Right value: $r'),
  ); // Prints Right value: 10
  right.when(
    ifLeft: (l) => print('Left: $l'),
    ifRight: (r) => print('Right: $r'),
  ); // Prints Right: Either.Right(10)
  // Or use Dart 3.0 switch expression syntax 🤘
  print(
    switch (right) {
      Left() => 'Left: $right',
      Right() => 'Right: $right',
    },
  ); // Prints Right: Either.Right(10)
}
