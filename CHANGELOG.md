## 2.1.0 - Feb 28, 2026

- Promote `Either.parSequenceN` and `Either.parTraverseN` from experimental to stable:
  - Removed `@experimental` annotation.
  - Changed from positional parameters to **named parameters** for clarity.
  - Added full documentation with examples.
  - Added unit tests.

- `Either.parSequenceN` — runs a list of async `Either`-returning functions in parallel with
  an optional concurrency limit. Short-circuits on the first `Left`.
  ```dart
  final result = await Either.parSequenceN<String, int>(
    functions: [
      () async => fetchNumber(1),
      () async => fetchNumber(2),
      () async => fetchNumber(3),
    ],
    maxConcurrent: 2,
  );
  ```

- `Either.parTraverseN` — traverses an iterable, maps each element to an async `Either`-returning
  function, then runs them in parallel with an optional concurrency limit. Short-circuits on the
  first `Left`. Shorthand for `Either.parSequenceN(functions: values.map(mapper), maxConcurrent: maxConcurrent)`.
  ```dart
  final result = await Either.parTraverseN<String, int, int>(
    values: [1, 2, 3],
    mapper: (id) => () async => fetchNumber(id),
    maxConcurrent: 2,
  );
  ```

## 2.0.0 - Sep 01, 2024

- Require Dart 3.0.0 or higher `>=3.0.0 <4.0.0`.

- Make `Either` a sealed class, `EitherEffect` a sealed class, and `ControlError` a final class.
  Now you can use exhaustive switch expressions on `Either` instances.
  ```dart
  final Either<String, int> either = Either.right(10);
  
  // Use the `when` method to handle
  either.when(
    ifLeft: (l) => print('Left: $l'),
    ifRight: (r) => print('Right: $r'),
  ); // Prints Right: Either.Right(10)
  
  // Or use Dart 3.0 switch expression syntax 🤘
  print(
    switch (either) {
      Left() => 'Left: $either',
      Right() => 'Right: $either',
    },
  ); // Prints Right: Either.Right(10)
  ```

## 1.0.0 - Aug 23, 2022

- This is our first stable release.

## 0.0.1 - Apr 27, 2021

- Initial version, created by Stagehand
