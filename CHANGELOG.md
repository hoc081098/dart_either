## Unreleased

### `Either`

- **Side-effect hooks**
  - Added `onLeft` and `onRight`; each runs an action on one side and returns
    the original `Either`.
  - Deprecated aliases remain: `tapLeft` → `onLeft`, `tap` → `onRight`.
- **Right-side predicate**
  - Added `isRightAnd` to match a `Right` value with a predicate.
  - `exists` remains as a deprecated alias.
- **Nullable extraction**
  - Added `getOrNull` for `Right` and `leftOrNull` for `Left`.
  - `orNull` remains as a deprecated alias of `getOrNull`.
- **Fallback values**
  - Added eager `getOrDefault(value)`.
  - Deprecated lazy `getOrElse(() => value)`; use `getOrDefault` for an eager
    fallback or `getOrHandle((left) => value)` for a lazy, left-aware fallback.
- **Composition**
  - `combine`: combine matching sides; otherwise return the sole `Left`.
  - `flatten`: convert `Either<L, Either<L, R>>` to `Either<L, R>`.
  - `merge`: extract the value from `Either<T, T>`.

### `EitherEffect`, `Either.binding`, and `Either.futureBinding`

- **Direct short-circuit**
  - Added `effect.raise(left)` to exit the owning scope with `Left(left)`.
  - It avoids an intermediate `Left` and returns `Never`, so it works in
    expressions such as `nullable ?? effect.raise('missing')`.
  - `ensure` and `ensureNotNull` now delegate their short-circuit paths to
    `raise`.
- **Variance-safe capability**
  - Reworked `EitherEffect<L>` from a covariant public class into an opaque,
    contravariant, scope-bound capability.
  - Unsafe widening that previously compiled is now rejected; safe narrowing
    is supported.
  - `bind` moved from an instance member to `BindEitherEffectExtension`.
    Standard unprefixed imports keep `effect.bind(either)` unchanged. Prefixed
    imports must use the extension override; selective imports must include the
    extension.
- **Scope lifetime**
  - Capabilities are now revoked when their sync or async binding scope ends.
  - Reusing a captured capability afterward throws `StateError`.
  - Swallowing a scope's short-circuit signal and then completing normally now
    throws `StateError` instead of producing `Right`.

### Documentation and verification

- Updated the README, runnable examples, API docs, variance guidance, and
  binding-scope docs.
- Added regression coverage for:
  - new APIs and deprecated aliases;
  - covariance widening and rejected external `EitherEffect` construction;
  - nested sync/async scopes, capability revocation, and intercepted
    short-circuits.
- CI now runs the complete suite on every configured Dart SDK and collects
  stable-SDK coverage.

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
