## Unreleased - Mar 01, 2026

- API naming alignment (non-breaking) toward Arrow/Kotlin naming:
  - Added new APIs:
    - `onLeft` (from `tapLeft`)
    - `onRight` (from `tap`)
    - `getOrNull` (from `orNull`)
    - `getOrDefault` (from `getOrElse`)
    - `isRightAnd` (from `exists`)
  - Kept old APIs as deprecated aliases for compatibility:
    - `tapLeft -> onLeft`
    - `tap -> onRight`
    - `orNull -> getOrNull`
    - `getOrElse -> getOrDefault`
    - `exists -> isRightAnd`

- `getOrDefault` now uses eager fallback value semantics:
  - Signature: `R getOrDefault(R defaultValue)`.
  - Use `getOrHandle((_) => ...)` for lazy fallback computation.

- Added `Either.combine`:
  - Combines two `Either<L, R>` values.
  - If both are `Right`, uses `combineRight`.
  - If both are `Left`, uses `combineLeft`.
  - If one is `Left` and the other is `Right`, returns the sole `Left`.
- Updated docs, examples, and tests for `Either.combine`.

- Added `Either.leftOrNull`, `Either.flatten`, and `Either.merge`.
- Updated docs, examples, and tests for `leftOrNull`, `flatten`, and `merge`.

- Updated docs and examples to the new names:
  - `README.md` API table and snippets.
  - `example/lib/dart_either_readme.dart`.

- Expanded tests for:
  - New API names.
  - Deprecated alias compatibility.
  - Eager (`getOrDefault`) vs lazy (`getOrHandle`) fallback behavior.

- Added repository skill documentation for API rename workflow:
  - `.github/skills/api-rename-flow/SKILL.md`.

## 2.1.0 - Mar 07, 2026

- Promoted `Either.parSequenceN` and `Either.parTraverseN` from experimental to stable.
- Added complete API docs and examples for `Either.parSequenceN` and `Either.parTraverseN`.
- Added unit tests for `Either.parSequenceN` and `Either.parTraverseN`, including concurrency-limit and short-circuit cases.
- Added `@useResult` annotations to public APIs that should not be ignored (for example: `isLeft`, `isRight`, `map`, `flatMap`, `swap`, `exists`, `all`, `toEitherStream`, `left`, `right`, and others).

### API migration notes

- `Either.parSequenceN` changed from positional parameters to named parameters:
  ```dart
  // Before (2.0.0)
  Either.parSequenceN<String, int>(functions, n);

  // Now (2.1.0)
  Either.parSequenceN<String, int>(
    functions: functions,
    maxConcurrent: n,
  );
  ```
- `Either.parTraverseN` changed from positional parameters to named parameters:
  ```dart
  // Before (2.0.0)
  Either.parTraverseN<String, int, int>(values, mapper, n);

  // Now (2.1.0)
  Either.parTraverseN<String, int, int>(
    values: values,
    mapper: mapper,
    maxConcurrent: n,
  );
  ```
- `maxConcurrent` controls concurrency.
  - Pass a number (for example `2`) to limit concurrency.
  - Pass `null` for unlimited concurrency.

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
