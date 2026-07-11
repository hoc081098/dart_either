# API naming alignment

This document tracks naming decisions that move `dart_either` closer to
Arrow/Kotlin where that also produces an idiomatic Dart API.

Statuses describe the current branch relative to `master`. Implemented items
are still listed under `Unreleased` in `CHANGELOG.md`; they have not been
assigned to a published version yet.

## Implemented migrations

| Previous API | Canonical API | Semantics | Compatibility status |
|---|---|---|---|
| `tapLeft` | `onLeft` | Run an action only for `Left`, then return the original `Either` | `tapLeft` remains as a deprecated alias |
| `tap` | `onRight` | Run an action only for `Right`, then return the original `Either` | `tap` remains as a deprecated alias |
| `orNull` | `getOrNull` | Return the `Right` value or `null` | `orNull` remains as a deprecated alias |
| `exists` | `isRightAnd` | Return `true` only for a `Right` that satisfies the predicate | `exists` remains as a deprecated alias |
| `getOrElse(() => R)` | `getOrDefault(R)` or `getOrHandle((L) => R)` | Use `getOrDefault` for an eager value and `getOrHandle` for a lazy, left-aware fallback | `getOrElse` remains deprecated and preserves its historical lazy behavior |

`getOrHandle` deliberately keeps its current name. Its callback receives the
`Left` value and runs lazily, while the deprecated `getOrElse` callback takes
no argument. Treating either method as a direct alias of eager
`getOrDefault` would change observable behavior.

## Added operations

| API | Location | Semantics |
|---|---|---|
| `combine` | `Either` | Combine two `Right` values or two `Left` values; otherwise return the sole `Left` |
| `leftOrNull` | `Either` | Return the `Left` value or `null` |
| `flatten` | `FlattenEitherExtension` | Flatten `Either<L, Either<L, R>>` to `Either<L, R>` |
| `merge` | `MergeEitherExtension` | Extract the value from `Either<T, T>` |

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
