## Unreleased

### Added

- Added `onLeft` and `onRight` for running a side effect on one side while
  returning the original `Either` unchanged.
- Added `isRightAnd` for checking whether an `Either` is `Right` and its value
  satisfies a predicate.
- Added extraction and fallback operations:
  - `getOrNull()` returns the `Right` value or `null`.
  - `leftOrNull()` returns the `Left` value or `null`.
  - `getOrDefault(value)` returns the `Right` value or an eagerly evaluated
    fallback value.
- Added composition operations:
  - `combine` combines two `Right` values or two `Left` values with the
    provided functions, and otherwise returns the sole `Left`.
  - `flatten` converts `Either<L, Either<L, R>>` to `Either<L, R>`.
  - `merge` extracts the value from `Either<T, T>`.
- Added `EitherEffect.raise(value)` — unconditionally short-circuits the
  surrounding `Either.binding` or `Either.futureBinding` scope with a `Left`.
  Its return type is `Never`, so it composes naturally as an expression (e.g.
  `nullable ?? effect.raise('missing')`). `ensure` and `ensureNotNull` now
  delegate their short-circuit path to `raise`.

### Changed

- Hardened `EitherEffect<L>` as an opaque, contravariant binding capability
  backed by a library-private final scope and a phantom function type. Unsafe
  widening and construction outside the library are compile-time errors, while
  supported binding syntax and behavior remain unchanged. The
  `effect.bind(either)`, `either.bind(effect)`, and `eitherFuture.bind(effect)`
  forms remain supported. The source-compatibility exception is prefixed
  imports and selective imports that omit `BindEitherEffectExtension`; keeping
  `effect.bind(either)` requires importing that extension unprefixed.
- Capabilities issued by `Either.binding` and `Either.futureBinding` are
  revoked when their binding scope completes. Invoking a captured capability
  afterward throws a `StateError`.
- Swallowing a binding scope's short-circuit signal and completing normally now
  throws a `StateError` instead of producing a `Right`.

### Deprecated

- Existing names remain available as deprecated compatibility aliases:
  - `tapLeft` in favor of `onLeft`.
  - `tap` in favor of `onRight`.
  - `exists` in favor of `isRightAnd`.
  - `orNull` in favor of `getOrNull`.
- Deprecated `getOrElse(() => value)`. Use `getOrDefault(value)` for an eager
  fallback, or `getOrHandle((left) => value)` for a lazy, left-aware fallback.
  `getOrElse` retains its existing lazy behavior during the deprecation period.

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
