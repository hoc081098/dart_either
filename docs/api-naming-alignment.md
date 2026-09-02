# API naming alignment

This document tracks naming decisions that move `dart_either` closer to
Arrow/Kotlin where that also produces an idiomatic and type-safe Dart API.
Arrow is a reference, not a one-to-one compatibility contract.

Statuses describe the current repository state. Changes prepared for `2.3.0`
are assigned to that version in `CHANGELOG.md`; verify the registry before
describing `2.3.0` as published.

## Upstream evidence and decision boundary

This registry was audited on 2026-08-28 against:

- [Arrow 2.2.3 `Either.kt`](https://github.com/arrow-kt/arrow/blob/2.2.3/arrow-libs/core/arrow-core/src/commonMain/kotlin/arrow/core/Either.kt),
  the latest stable release at the time of the audit.
- [Arrow `main` at commit `4024286`](https://github.com/arrow-kt/arrow/blob/402428611aef5a2c232add0efb3a84200772df92/arrow-libs/core/arrow-core/src/commonMain/kotlin/arrow/core/Either.kt),
  whose `Either.kt` matched the 2.2.3 source byte-for-byte during the audit.
- [Arrow PR #2830](https://github.com/arrow-kt/arrow/pull/2830), the merged
  2022 proposal that reduced and renamed the Arrow `Either` API in preparation
  for Arrow 2.x.
- [Dart's keyword list](https://dart.dev/language/keywords), for names that
  cannot be expressed as Dart identifiers.

PR #2830 is historical design evidence, not the current Arrow API contract.
When its proposal conflicts with the audited source, the current source wins.
For example, the PR proposed replacing `handleErrorWith` and `combine`, but the
audited source still contains both operations.

Important decisions after PR #2830 include predicate-based `isLeft`/`isRight`
in [PR #2927](https://github.com/arrow-kt/arrow/pull/2927), `leftOrNull` and a
broader move toward `getOrElse` in
[PR #2968](https://github.com/arrow-kt/arrow/pull/2968), and the restoration of
`handleErrorWith` in [PR #3456](https://github.com/arrow-kt/arrow/pull/3456).

The audited Arrow source also deliberately mixes declaration forms: `fold`,
`map`, `mapLeft`, `onLeft`, `onRight`, and `getOrNull` are class members;
`flatMap`, `handleErrorWith`, `getOrElse`, `flatten`, `merge`, `combine`, and
`recover` are top-level extensions. Arrow also has a typed recovery extension
named `catch`, while construction-time `Either.catch` belongs to the companion
object. This is evidence for a variance- and receiver-shaped API, not a
placement map to copy verbatim into Dart.

The upstream sources answer naming and semantic questions. They do not decide
whether a Dart operation must be an instance member or an extension; that is
governed by Dart variance safety and this package's compatibility policy.

## Declaration placement policy

An operation can conceptually belong to `Either` without being declared inside
the `Either` class. Declaration placement is determined mechanically:

| Declaration | Rule | Examples |
|---|---|---|
| `Either` instance member | The receiver is unconstrained `Either<L, R>` and every occurrence of `L` and `R` is safe at a covariant virtual-method boundary | `fold`, `map`, `mapLeft`, `swap`, `onLeft`, `onRight`, `getOrNull` |
| Generic extension on `Either` | An `L` or `R` occurs negatively or invariantly in the operation's signature | `flatMap`, `getOrDefault`, `combine`, and the final left-aware `getOrElse` |
| Specialized extension on `Either` | The operation exists only for a constrained or refined receiver shape | `flatten`, `merge`, `toFuture`, `getOrThrow` |
| `Either` static member | The operation constructs, handles, or combines values without consuming the enclosing class's `L` or `R` | `tryCatch`, `tryCatchAsync`, `binding`, `bindingAsync`, `sequence`, `traverse` |
| Extension on another receiver | The operation adapts a foreign type into or through `Either` | `Future.toEitherFuture`, `Stream.toEitherStream`, `T.left`, `T.right` |
| Binding extension | The operation belongs to the scoped `EitherEffect` capability rather than the `Either` value | `bind`, `raise`, `ensure`, `ensureNotNull` |

Examples in this table describe the preferred declaration for a canonical API,
not necessarily every legacy declaration that remains during 2.x. In
particular, an unsafe existing member such as `flatMap` cannot be silently
relocated by a naming-only change.

See [Either variance safety](either-variance-safety.md) for the complete sign
audit and widened-receiver failure mode. Source-file organization is secondary
to this public declaration rule: one method per file is appropriate for named
extensions, but a safe instance member must not become an extension merely to
split the implementation across files.

### Non-breaking 2.x rename rule

For every rename introduced during `2.x`:

1. If the existing operation is a variance-safe instance member, add the
   canonical name as an instance member and keep the old member as a deprecated
   forwarding alias.
2. If the existing operation is unsafe as an instance member, add the canonical
   name as a named generic extension implemented through direct pattern
   matching or a proven safe primitive. Keep the old instance member in place,
   with unchanged behavior, as a deprecated compatibility API for all of `2.x`.
3. If the existing operation is already an extension, keep both the canonical
   operation and its deprecated alias as exported named extensions.
4. If the existing operation is static, keep both names static unless the new
   semantics require a deliberately different abstraction.
5. Do not relocate or remove the old declaration in the same 2.x change that
   introduces its replacement. Declaration cleanup belongs to a planned major
   release.

An extension-backed canonical name remains available with normal call syntax
when its extension is imported unprefixed. Prefixed imports, selective imports
that omit the extension, and `dynamic` receivers behave differently. Adding a
new extension name does not break existing source, but moving an existing
instance member to an extension can; this is why rename and relocation are
separate changes.

## Complete rename registry

The table distinguishes implemented migrations, planned breaking cleanup,
open semantic decisions, and rejected proposals. "Arrow evidence" records what
the upstream source actually says; it does not automatically prescribe the
Dart decision.

| Current or previous Dart API | Canonical target | Status | Arrow evidence | Dart placement and compatibility |
|---|---|---|---|---|
| `tapLeft` | `onLeft` | Implemented in 2.2.0 | PR #2830 directly renamed `tapLeft` to `onLeft`; current Arrow keeps `onLeft` | Safe `Either` member; `tapLeft` remains a deprecated member alias |
| `tap` | `onRight` | Implemented in 2.2.0 | PR #2830 directly renamed `tap` to `onRight`; current Arrow keeps `onRight` | Safe `Either` member; `tap` remains a deprecated member alias |
| `orNull` | `getOrNull` | Implemented in 2.2.0 | PR #2830 directly renamed `orNull` to `getOrNull`; current Arrow keeps `getOrNull` | Safe `Either` member; `orNull` remains a deprecated member alias |
| `exists` | `isRightAnd` | Implemented in 2.2.0 | PR #2830 removed `exists`; Arrow PR #2927 later added predicate overloads of `isRight` | Dart already exposes `isRight` as a getter and has no overloads, so `isRightAnd` is the Dart adaptation; `exists` remains deprecated |
| No previous Dart API | `isLeftAnd` | Implemented in 2.3.0 | Arrow PR #2927 added a predicate overload of `isLeft` | Dart already exposes `isLeft` as a getter and has no overloads, so `isLeftAnd` is the Dart adaptation; no deprecated alias is needed |
| `getOrElse(R Function())` | `getOrDefault(R)` or `getOrHandle(R Function(L))` | Implemented 2.x migration | Current Arrow's `getOrElse` is lazy and receives the `Left` value; Arrow has no eager `getOrDefault` on `Either` | `getOrDefault` is a Dart-specific safe extension; `getOrHandle` remains the temporary left-aware member; legacy `getOrElse` remains deprecated with its original lazy, zero-argument behavior |
| `getOrHandle(R Function(L))` | `getOrElse(R Function(L))` | Planned for 3.0.0 only | PR #2830 called `getOrHandle` a duplicate of `getOrElse`; current Arrow exposes only left-aware `getOrElse` | Remove both 2.x fallback members in 3.0.0 and introduce the final `getOrElse` as a generic extension |
| `handleError(R Function(L))` | No direct rename | Reviewed; retain in 2.x | PR #2830 initially replaced it through `recover`, but [Arrow's later final deprecation](https://github.com/arrow-kt/arrow/commit/b6a00df2a234131f62c95812958bad406641b13f) was `getOrElse(f).right()` and current Arrow has no `handleError` | Arrow `recover` is a richer Raise-DSL operation, not a compatibility alias. Treat any deprecation/removal and variance hardening as separate work |
| `handleErrorWith(Either<L2, R> Function(L))` | `handleErrorWith` | Reviewed; retain the name | PR #2830 proposed replacement through `recover`, but PR #3456 restored `handleErrorWith` and current Arrow exposes it | No rename. Its unsafe legacy instance placement may be handled separately from naming |
| Proposed `recoverWith` | No Arrow target | Rejected as Arrow alignment | Current Arrow exposes `handleErrorWith` and richer `recover`, but no `recoverWith` | Remove it from the rename candidates; reconsider only as an explicitly Dart/Cats-style API proposal |
| `futureBinding` | `bindingAsync` | Implemented in 2.3.0 | No direct Arrow equivalent; Arrow's [typed-errors guide](https://arrow-kt.io/learn/typed-errors/working-with-typed-errors/) uses the same `either { }` builder from synchronous and suspending functions | The async suffix keeps the family grouped with `binding` and matches `tryCatchAsync`; `futureBinding` remains a deprecated static alias with identical `FutureOr` callback and scope semantics |
| `catchError` | `tryCatch` | Implemented in 2.3.0 | The closest Arrow API is companion `Either.catch`, but it returns `Either<Throwable, R>` and does not take Dart's mapper plus `StackTrace` | `catch` is a reserved Dart keyword. `tryCatch` keeps the synchronous factory shape while using required named parameters; `catchError` remains a deprecated positional alias |
| `catchFutureError` | `tryCatchAsync` | Implemented in 2.3.0 | No direct Arrow `Either` equivalent | The async suffix keeps the family grouped with `tryCatch`; `catchFutureError` remains a deprecated positional static alias |
| `catchStreamError` | `Stream.toEitherStream` | Implemented in 2.3.0 | No direct Arrow `Either` equivalent | A `Stream` is a multi-event foreign receiver rather than a one-shot computation. The existing receiver adapter is canonical; `catchStreamError` remains a deprecated positional static alias |

`registerFatalError<T>()` is a Dart-specific error-capture policy rather than
an Arrow naming migration. It lets an application declare that values of `T`,
including subtypes, must be rethrown by the catch family instead of being
mapped to `Left`. Registration is isolate-local, additive, and idempotent.

### Fallback migration details

`getOrHandle` deliberately keeps its current name during `2.x`. Its callback
receives the `Left` value and runs lazily, while the deprecated `getOrElse`
callback takes no argument. Treating either method as a direct alias of eager
`getOrDefault` would change observable behavior.

`getOrDefault` is declared by `GetOrDefaultEitherExtension` rather than as an
instance member. This preserves the same call syntax while avoiding a runtime
type check against a covariantly widened receiver.

In `3.0.0`, only these fallback operations remain:

```dart
R getOrDefault(R defaultValue);                   // Eager fallback value.
R getOrElse(R Function(L value) defaultValue);    // Lazy, left-aware fallback.
```

Use this migration sequence:

1. Keep `getOrElse(() => R)` deprecated throughout `2.x` and use
   `getOrHandle((L) => R)` as the non-breaking, left-aware API.
2. In `3.0.0`, remove both `getOrHandle((L) => R)` and the legacy
   `getOrElse(() => R)` signature.
3. Introduce `getOrElse((L) => R)` as the only lazy, left-aware fallback.

| 2.x call | 3.x migration |
|---|---|
| `getOrDefault(value)` | Unchanged |
| `getOrHandle((left) => fallback)` | `getOrElse((left) => fallback)` |
| `getOrElse(() => fallback)` | `getOrElse((_) => fallback)` for lazy evaluation, or `getOrDefault(fallback)` for an eager value |

Do not reuse `getOrElse` with the new callback signature in a minor release;
the identical method name would hide a source-breaking signature change. Do
not retain `getOrHandle` as a deprecated alias in 3.x; its removal is part of
the same planned major migration.

## Reviewed Arrow changes that are not renames

PR #2830 also proposed removing or composing away many operations. Those are
API-size decisions, not rename instructions, and must not be smuggled into a
2.x naming change.

| Current Dart API | PR #2830 direction | Audited Arrow source | Dart 2.x decision |
|---|---|---|---|
| `foldLeft` | Replace with `fold` | Absent from the audited `Either.kt` | No rename; any deprecation or removal is major-version work |
| `bimap` | Replace with `map` plus recovery/mapping | Absent from the audited `Either.kt` | No rename; evaluate separately as API-surface cleanup |
| `all` | Replace with `fold` | Absent from the audited `Either.kt` | No rename; retain in 2.x |
| `findOrNull` | Replace with Kotlin nullable chaining | Absent from the audited `Either.kt` | No rename; Kotlin's replacement is not a direct Dart API name |
| `redeem` | Replace with `map` plus `recover` | Absent from the audited `Either.kt` | No rename; retain in 2.x as the single-callback-per-input operation that maps either original channel into a runtime `Right` while keeping `L` in the declared return type |
| `redeemWith` | Replace with `fold` | Absent from the audited `Either.kt` | No rename; retain in 2.x as the operation that lets either original channel return `Either<L2, R2>` directly; any removal is major-version work |
| `fromNullable` | Replace with Kotlin nullable syntax or Raise DSL | Absent from the audited `Either.kt` | Retain as a Dart boundary helper; no rename |
| `combine` | Replace later with accumulating zip behavior | Present as `combine` in the audited source | Keep the existing name |
| `sequence`, `traverse` | Remove the Either-specific traversal family | Absent from the audited `Either.kt` | Retain Dart's collection helpers; review behavior separately from naming |
| `when` | Kotlin uses the language `when` expression | No Arrow method | Retain in 2.x; Dart 3 pattern matching is already documented as an alternative |

PR-only names with no matching `dart_either` value operation are intentionally
not rename candidates: `replicate`, `void`, `filterOrElse`, `filterOrOther`,
`contains`, `widen`, historical `leftWiden` (written as `widenLeft` in the PR
body), `zip`, `combineK`, `orNone` (renamed upstream to `getOrNone` but not
applicable without a Dart `Option` API), nullable-side
constructors (`rightIfNotNull`, `rightIfNull`, and `leftIfNull`), `isEmpty`,
`isNotEmpty`, `combineAll`, `foldMap`, `bifoldLeft`, `bifoldMap`, `bitraverse`,
and the Option/Validated traversal variants. Arrow's former instance-level
`ensure` was replaced by its Raise DSL; Dart already exposes the corresponding
scoped operation as `EitherEffect.ensure`.

Already-aligned names needing no migration include `fold`, `swap`, `map`,
`mapLeft`, `flatMap`, `onLeft`, `onRight`, `getOrNull`, `leftOrNull`,
`isLeftAnd`, `isRightAnd`, `flatten`, `merge`, `combine`, `left`, and `right`.
Dart-specific APIs such as binding, bounded parallel traversal, Future/Stream
adapters, `toFuture`, and `getOrThrow` have no direct Arrow naming contract.

In particular, Arrow's `catchOrThrow` constructs an `Either` while selectively
catching a throwable type; Dart's `getOrThrow` extracts an existing `Either`.
The similar suffix does not make them rename counterparts. Arrow operations
such as `validate`, `toIor`, and `zipOrAccumulate` are also new-feature inputs,
not missing rename targets.

## Added and deferred operations

| API | Location | Status and semantics |
|---|---|---|
| `combine` | `CombineEitherExtension` | Implemented; combine two `Right` values or two `Left` values, otherwise return the sole `Left` |
| `leftOrNull` | `Either` | Implemented; return the `Left` value or `null` |
| `flatten` | `FlattenEitherExtension` | Implemented; flatten `Either<L, Either<L, R>>` to `Either<L, R>` |
| `merge` | `MergeEitherExtension` | Implemented; extract the value from `Either<T, T>` |
| `EitherEffect.raise` | `RaiseEitherEffectExtension` | Implemented; short-circuit directly with a left value |
| `isLeftAnd` | Safe `Either` member | Implemented in 2.3.0; adapts Arrow's predicate overload of `isLeft` because Dart already uses an `isLeft` getter |
| Arrow-style `recover` | Generic extension plus scoped `Raise` capability | Deferred new API, not a rename; it must support returning a success value or raising a new left value and must not be introduced as a weaker alias of `handleError` or `handleErrorWith` |

Deferred or rejected names must not appear in usage examples as available
APIs.

## `EitherEffect` 2.x compatibility boundary

The internal `EitherEffect<L>` representation hardening recorded in
[ADR 0001](adr/0001-scope-bound-contravariant-either-effect.md) targets a
`2.x.y` release. Supported source usage and runtime behavior remain unchanged:
callers receive the capability from `Either.binding` or `Either.bindingAsync`
and use the existing binding extensions within that scope. The deprecated
`Either.futureBinding` alias preserves the same asynchronous behavior. The
source-compatibility exception is prefixed imports and selective imports that
omit `BindEitherEffectExtension`; keeping `effect.bind(either)` requires
importing that extension unprefixed. Constructing, implementing, destructuring,
replacing the binding behavior of, or invoking a captured `EitherEffect` after
its scope settles is outside the supported contract and does not require a
compatibility migration.

## Compatibility checklist

For every public rename:

1. Apply the declaration placement policy and audit all `L` and `R`
   occurrences before choosing a member or extension.
2. Add and document the canonical API.
3. Keep the previous API as a deprecated alias with unchanged semantics and
   declaration placement throughout `2.x`.
4. Cover the canonical API in the main test suite and the alias in
   `test/deprecated_aliases_test.dart`.
5. Update `CHANGELOG.md`, `README.md`, `example/`, Dart doc snippets, and this
   document in the same change.
6. Remove or relocate deprecated declarations only in a planned major release.
