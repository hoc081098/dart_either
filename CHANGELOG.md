## Unreleased

This section targets the next major release, `3.0.0`, because it contains
public breaking changes. The package version remains `2.2.0` until final
release preparation.

### `Either`

- **Breaking variance-safe extension migration**
  - Moved `flatMap`, `getOrElse`, `getOrHandle`, `handleError`, and
    `handleErrorWith` from virtual `Either<L, R>` instance members to same-name
    generic extensions.
  - Each operation now lives in its own source file and pattern-matches
    directly on `Left` / `Right`, preventing runtime `TypeError` failures for
    analyzer-valid covariantly widened values.
  - Ordinary calls through an unprefixed
    `package:dart_either/dart_either.dart` import keep the same syntax.
    Prefixed or selective imports must expose or invoke the relevant extension
    explicitly, and these operations are no longer available through a
    `dynamic` receiver.
  - The current `getOrElse` and `getOrHandle` extension shapes are an
    intermediate branch state. Final `3.0.0` preparation removes `getOrHandle`
    and changes `getOrElse` to accept the `Left` value, as documented in the
    API naming migration.

## 2.2.0 - Aug 27, 2026

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

### Import migration for `EitherEffect.bind`

The usual unprefixed package import keeps the existing call syntax. With a
prefixed import, invoke the named extension explicitly:

```dart
import 'package:dart_either/dart_either.dart' as de;

final result = de.Either<String, int>.binding((effect) {
  return de.BindEitherEffectExtension(effect).bind(
    de.Either<String, int>.right(1),
  );
});
```

For a selective unprefixed import, include `BindEitherEffectExtension` in the
`show` list. The Dart SDK constraint remains `>=3.0.0 <4.0.0`.

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
