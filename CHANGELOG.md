## Unreleased

### `Either`

- **Side-effect hooks:** Added `onLeft` and `onRight` for running an action on
  one side while returning the original `Either` unchanged. `tapLeft` and
  `tap` remain available as deprecated aliases of `onLeft` and `onRight`,
  respectively.
- **Right-side predicate:** Added `isRightAnd` for checking that an `Either` is
  `Right` and its value satisfies a predicate. `exists` remains available as a
  deprecated alias.
- **Nullable extraction:** Added `getOrNull` for extracting a `Right` value and
  `leftOrNull` for extracting a `Left` value. `orNull` remains available as a
  deprecated alias of `getOrNull`.
- **Fallback values:** Added `getOrDefault(value)` for an eager fallback value.
  The historical lazy `getOrElse(() => value)` remains available but is
  deprecated; use `getOrDefault` for an eager fallback or the existing
  `getOrHandle((left) => value)` for a lazy, left-aware fallback.
- **Composition:** Added `combine` for combining two `Either` values, `flatten`
  for converting `Either<L, Either<L, R>>` to `Either<L, R>`, and `merge` for
  extracting the value from `Either<T, T>`.

### `EitherEffect`, `Either.binding`, and `Either.futureBinding`

- **Direct short-circuit:** Added `effect.raise(left)`, which exits the owning
  binding scope with `Left(left)`. It avoids constructing a `Left` solely to
  bind it and returns `Never`, so it can be used in expressions such as
  `nullable ?? effect.raise('missing')`. `ensure` and `ensureNotNull` now use
  `raise` for their short-circuit paths.
- **Variance and ownership:** Hardened `EitherEffect<L>` into an opaque,
  contravariant, scope-bound capability backed by a library-private final
  implementation. Unsafe widening and construction outside the library are
  rejected at compile time.
- **Scope lifetime:** A capability is valid only while its sync or async binding
  scope is active. Invoking a captured capability after the scope completes
  throws `StateError`. Swallowing the scope's short-circuit signal and then
  completing normally also throws `StateError` instead of producing `Right`.
- **Binding syntax:** `effect.bind(either)`, `either.bind(effect)`,
  `eitherFuture.bind(effect)`, and `effect.bindFuture(eitherFuture)` remain
  supported. With the standard unprefixed package import, their call syntax is
  unchanged. Prefixed imports must use the `BindEitherEffectExtension`
  extension override, and selective imports must include that extension.

### Documentation and verification

- Expanded the README, runnable examples, API documentation, variance-safety
  guidance, and binding-scope documentation for the new APIs and behavior.
- Added regression coverage for the new operations and deprecated aliases,
  covariance widening, nested sync and async scopes, capability revocation,
  intercepted short-circuits, and rejected external `EitherEffect`
  construction.
- Updated CI to run the complete test suite on every configured Dart SDK and
  collect coverage on the stable SDK.

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
