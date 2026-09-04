## Unreleased

- Relocated `flatMap`, deprecated `getOrElse`, `getOrHandle`, `handleError`,
  and `handleErrorWith` from `Either` instance members to exported generic
  extensions. Statically typed dot-call syntax and behavior are unchanged,
  while analyzer-valid widened receivers no longer fail at a covariant virtual
  method boundary. Selective imports must include the relevant extension type,
  and `dynamic` receivers no longer dispatch to these operations.
- Split every value-operation extension exported by `either_extensions.dart`
  into a method-named source file, with mirrored tests under
  `test/either_extensions/`.

- Fixed `Either.parSequenceN` and `Either.parTraverseN` with finite concurrency
  so functions still waiting for a permit are not invoked after the first
  observed `Left`, thrown error, or failed future. A `Left` is returned when it
  is observed first; an ordinary error observed first is propagated with its
  stack trace. Already-running functions remain non-cancellable and may finish
  their side effects.
- A non-null `maxConcurrent` less than or equal to zero now throws an
  `ArgumentError` synchronously, before inputs are traversed, the
  `parTraverseN` mapper is called, or callbacks are invoked.

## 2.3.0 - Sep 02, 2026

- Added `isLeftAnd`, which evaluates a predicate for `Left` values and returns
  `false` for `Right` values.

- Added `tryCatch` and `tryCatchAsync` as the canonical synchronous and
  asynchronous error-capture APIs. Both use required named `action` and
  `errorMapper` parameters. `tryCatchAsync` captures errors thrown before a
  future is returned as well as errors that complete the future.
  - Deprecated `catchError` in favor of `tryCatch`.
  - Deprecated `catchFutureError` in favor of `tryCatchAsync`.
  - Deprecated `catchStreamError` in favor of `Stream.toEitherStream`.
  - The deprecated aliases retain their existing call syntax throughout `2.x`.

- Added `registerFatalError<T>()` to exclude a registered error type and its
  subtypes from conversion to `Left`. Registered errors retain their original
  error and stack trace across `tryCatch`, `tryCatchAsync`,
  `Future.toEitherFuture`, and `Stream.toEitherStream`.
  Registration is per isolate, additive, and idempotent; spawned isolates must
  register their own fatal types.

- Added `bindingAsync` as the canonical asynchronous counterpart to `binding`.
  Deprecated `futureBinding` in favor of `bindingAsync`; the alias retains its
  existing call syntax and behavior throughout `2.x`.

- Fixed `handleError` to preserve the original `Right` instance instead of
  creating an equivalent one. Callback invocation and `Left` recovery behavior
  are unchanged.

- Clarified the channel and callback semantics of `handleErrorWith`,
  `handleError`, `redeem`, and `redeemWith`.

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
