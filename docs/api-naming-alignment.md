# API naming alignment

This document tracks naming decisions that move `dart_either` closer to
Arrow/Kotlin where that also produces an idiomatic Dart API.

Statuses describe the current repository state. Implemented items are listed
under `Unreleased` in `CHANGELOG.md` and target the next major release,
`3.0.0`; they have not been published yet.

## Implemented migrations

| Previous API | Canonical API | Semantics | Compatibility status |
|---|---|---|---|
| `tapLeft` | `onLeft` | Run an action only for `Left`, then return the original `Either` | `tapLeft` remains as a deprecated alias |
| `tap` | `onRight` | Run an action only for `Right`, then return the original `Either` | `tap` remains as a deprecated alias |
| `orNull` | `getOrNull` | Return the `Right` value or `null` | `orNull` remains as a deprecated alias |
| `exists` | `isRightAnd` | Return `true` only for a `Right` that satisfies the predicate | `exists` remains as a deprecated alias |
| `getOrElse(() => R)` | `getOrDefault(R)` or `getOrHandle((L) => R)` | Use `getOrDefault` for an eager value and `getOrHandle` for a lazy, left-aware fallback | `getOrElse` remains deprecated and preserves its historical lazy behavior |

`getOrHandle` deliberately keeps its current name during the present
deprecation window. Its callback receives the `Left` value and runs lazily,
while the deprecated `getOrElse` callback takes no argument. Treating either
method as a direct alias of eager `getOrDefault` would change observable
behavior.

`getOrDefault` and the callback-producing operations listed below are generic
extensions rather than instance members. This preserves ordinary call syntax
while avoiding runtime checks against a covariantly widened virtual receiver.
See [Either variance safety](either-variance-safety.md).

## Variance-safe location changes (no rename)

These operations keep their public names but no longer live on `Either`:

| API | Extension | Source file |
|---|---|---|
| `flatMap` | `FlatMapEitherExtension` | `lib/src/either_extensions/flat_map.dart` |
| `getOrElse` | `GetOrElseEitherExtension` | `lib/src/either_extensions/get_or_else.dart` |
| `getOrHandle` | `GetOrHandleEitherExtension` | `lib/src/either_extensions/get_or_handle.dart` |
| `handleError` | `HandleErrorEitherExtension` | `lib/src/either_extensions/handle_error.dart` |
| `handleErrorWith` | `HandleErrorWithEitherExtension` | `lib/src/either_extensions/handle_error_with.dart` |

Each extension matches `Left` and `Right` directly and has widened covariance
regression coverage. This is intentionally not an API rename. Normal calls
through an unprefixed barrel import remain `either.flatMap(...)`,
`either.getOrHandle(...)`, and so on.

The location change is nevertheless source-breaking for prefixed imports,
selective imports that omit the extension declaration, and calls through a
`dynamic` receiver. It must ship under a release policy that permits that
compatibility break.

## `EitherEffect` compatibility boundary

The internal `EitherEffect<L>` representation hardening recorded in
[ADR 0001](adr/0001-scope-bound-contravariant-either-effect.md) preserves
supported source usage and runtime behavior: callers receive the capability
from `Either.binding` or `Either.futureBinding` and use the existing binding
extensions within that scope. The source-compatibility exception is prefixed
imports and selective imports that omit `BindEitherEffectExtension`; keeping
`effect.bind(either)` requires importing that extension unprefixed.
Constructing, implementing, destructuring, replacing the binding behavior of,
or invoking a captured `EitherEffect` after its scope settles is outside the
supported contract and does not require a compatibility migration.

## Planned major-version cleanup

`getOrHandle` is a compatibility bridge rather than the preferred final name.
Once a major release can remove the legacy `getOrElse(() => R)` signature, the
target API is:

```dart
R getOrDefault(R defaultValue);                   // Eager fallback value.
R getOrElse(R Function(L value) defaultValue);    // Lazy, left-aware fallback.
```

This final shape aligns the lazy fallback with Arrow's `getOrElse` while
keeping eager evaluation explicit through `getOrDefault`.

Use this migration sequence:

1. Keep `getOrElse(() => R)` deprecated during the current migration window
   and use `getOrHandle((L) => R)` as the current left-aware API.
2. In the next planned major release, remove the legacy zero-argument
   `getOrElse` signature.
3. Introduce `getOrElse((L) => R)` as the canonical lazy fallback.
4. Keep `getOrHandle((L) => R)` as a deprecated alias to the new `getOrElse`
   for a migration window; remove it only in a later planned major release.

Do not reuse `getOrElse` with the new callback signature in a minor release;
the identical method name would hide a source-breaking signature change.

## Added operations

| API | Location | Semantics |
|---|---|---|
| `combine` | `CombineEitherExtension` | Combine two `Right` values or two `Left` values; otherwise return the sole `Left` |
| `leftOrNull` | `Either` | Return the `Left` value or `null` |
| `flatten` | `FlattenEitherExtension` | Flatten `Either<L, Either<L, R>>` to `Either<L, R>` |
| `merge` | `MergeEitherExtension` | Extract the value from `Either<T, T>` |
| `EitherEffect.raise` | `RaiseEitherEffectExtension` | Short-circuit directly with a left value without constructing a `Left` solely to bind it |

## Deferred proposals

These names are ideas only. They are not implemented and must not appear in
usage examples as available APIs.

| Current API | Candidate | Status |
|---|---|---|
| No predicate-based left helper | `isLeftAnd` | Deferred |
| `handleError` | `recover` | Deferred |
| `handleErrorWith` | `recoverWith` | Deferred |
| `catchError` | `catch` | Deferred |
| `catchFutureError` | `catchFuture` | Deferred |
| `catchStreamError` | `catchStream` | Deferred |

## Compatibility policy

For every public rename:

1. Add and document the canonical API.
2. Keep the previous API as a deprecated alias with unchanged semantics.
3. Cover the canonical API in the main test suite and the alias in
   `test/deprecated_aliases_test.dart`.
4. Update `CHANGELOG.md`, `README.md`, `example/`, Dart doc snippets, and this
   document in the same change.
5. Remove deprecated aliases only in a planned major release.
