# `dart_either`: current strengths and improvement roadmap

This note distills an earlier discussion about the value proposition of
`dart_either` and the improvements that could make it more robust. It is not a
transcript or marketing copy. Every technical statement below was reconciled
with repository `master` at commit `69ec7b1` on 2026-08-23.

The package currently declares version `2.1.0`; changes under `Unreleased` in
the [changelog](../CHANGELOG.md) are present on `master` but must not be
described as part of the published `2.1.0` API without checking the release.

## Executive summary

The strongest proposition is not that `Either` itself is difficult to write.
`Left` and `Right` are the inexpensive part. The library's value is the
coherent application-facing surface around them: transformations, recovery,
nullable and exception bridges, async composition, collection traversal, and
direct-style `binding` scopes, backed by documentation and edge-case tests.

The current implementation is a credible focused alternative for projects
that want typed failure without importing a broader FP toolkit. Its most
distinctive feature is `Either.binding` / `Either.futureBinding`: sequential
typed-failure code can retain ordinary Dart control flow (`await`, local
variables, `if`, and `return`) while short-circuiting on the first `Left`.

The code is stronger than the earlier conversation's snapshot in several
areas. `EitherEffect` is no longer the proposed forgeable structural record;
it is now an opaque, scope-bound, contravariant capability backed by a private
final class. Captured capabilities are revoked, intercepted short-circuits are
detected, `raise` is implemented, and the full test suite runs in CI.

The main remaining technical debt is not a lack of more convenience methods.
It is semantic precision:

1. finish the variance audit for legacy instance methods;
2. define and test what parallel "short-circuit" does to still-running and
   queued work;
3. make nullable and exception conversion more domain-selective;
4. decide whether `BuiltList` still fits the lightweight positioning; and
5. strengthen law, lower-bound, documentation, and package validation.

## Why the library is useful

### A focused scope

The public barrel exports `Either`, its binding capability, and related
extensions. It does not bring in `Reader`, `Writer`, lenses, HKT emulation, or
a monad-transformer stack. That matches the practical requirement that
motivated the earlier discussion: use a complete `Either` without adopting an
entire FP framework.

The "lightweight" claim needs one qualification. Runtime dependencies are only
`meta` and `built_collection`, but `BuiltList` is exposed in the return types of
`sequence`, `traverse`, `parSequenceN`, and `parTraverseN`. It is therefore part
of the public API and not merely an internal implementation detail.

### The API around `Either` is the product

The current API covers the operations that make `Either` practical in an app:

- construction and inspection with `left`, `right`, pattern matching,
  `isLeft`, and `isRight`;
- transformation and composition with `map`, `mapLeft`, `flatMap`, `bimap`,
  `fold`, `combine`, `flatten`, `merge`, and `swap`;
- recovery and extraction with `getOrNull`, `leftOrNull`, `getOrDefault`,
  `getOrHandle`, `handleError`, and `handleErrorWith`;
- exception, `Future`, and `Stream` bridges through `catchError`,
  `catchFutureError`, `catchStreamError`, `toEitherFuture`, and
  `toEitherStream`;
- async chaining with `thenMapEither` and `thenFlatMapEither`;
- sequential and parallel collection operations through `sequence`,
  `traverse`, `parSequenceN`, and `parTraverseN`; and
- direct-style composition through `binding`, `futureBinding`, `bind`,
  `bindFuture`, `ensure`, `ensureNotNull`, and `raise`.

`traverse` and `sequence` remain useful for batch validation or transforming a
collection of fallible operations. In ordinary Repository/UseCase code,
however, `binding` and `futureBinding` are usually the more differentiating
feature because they remove nested `flatMap` while preserving explicit typed
failure.

### Direct-style typed failure

This is valid current syntax; `Future<Either<L, R>>.bind(effect)` is provided by
`BindEitherFutureExtension`:

```dart
final result = await Either.futureBinding<AppError, Output>((effect) async {
  final a = await getA().bind(effect);
  final b = await getB(a).bind(effect);
  effect.ensure(b.isValid, () => const AppError.invalid());
  return build(a, b);
});
```

The success path reads like normal Dart. The failure path remains visible in
the outer type `Future<Either<AppError, Output>>`, unlike an undocumented
thrown domain exception.

A compact positioning statement that matches the implementation is:

> Either itself is simple. Making Either pleasant, safe, and practical in
> real-world Dart and Flutter code is the hard part.

An alternative with more personality is:

> Anyone can write `Left` and `Right`. The hard part is designing an Either API
> that people actually want to use every day.

These describe the engineering goal. Claims such as "the most complete Either
library" or "better than `either_dart`" require a fresh competitor audit before
publication; the local repository alone cannot establish them.

## What `binding` actually guarantees

The current implementation uses an internal thrown `ControlError` as an
abortive control-flow signal:

```text
bind(Right(value)) -> return value and continue

bind(Left(error)) or raise(error)
  -> mark the scope as raised
  -> throw ControlError(error, scopeToken)
  -> unwind the binding callback
  -> matching boundary returns Left(error)
```

Important guarantees visible in
[`lib/src/dart_either.dart`](../lib/src/dart_either.dart),
[`lib/src/binding.dart`](../lib/src/binding.dart), and
[`test/either_effect_test.dart`](../test/either_effect_test.dart) are:

- Every `binding` or `futureBinding` call creates its own token. A boundary
  catches only a `ControlError` with the identical token, so nested scopes do
  not consume one another's short-circuit.
- `Right` values are unwrapped. `Left` and `raise` terminate only the owning
  binding scope.
- Ordinary exceptions and failed futures propagate unchanged. They are not
  silently converted to `Left`.
- Explicit conversion is available through `catchError`, `catchFutureError`,
  and `catchStreamError`. Their `ErrorMapper` receives both the object and its
  `StackTrace`.
- Those helpers call the internal `throwIfFatal` guard, which rethrows
  `ControlError` instead of mapping a binding short-circuit into a domain
  `Left`.
- The capability remains active across work returned from `futureBinding`,
  then is closed when the computation settles. Using a captured capability
  afterward throws `StateError`.
- If user code catches the scope's `ControlError`, swallows it, and completes
  normally, the boundary throws a `StateError` with the message
  `Binding short-circuit was intercepted.` instead of manufacturing a
  `Right`.
- `EitherEffect<L>` is contravariant. Safe narrowing is accepted, while unsafe
  widening is rejected by the analyzer.
- External code cannot construct, extend, implement, or replace the binding
  behavior of `EitherEffect`.

The representation is:

```dart
typedef EitherEffect<L> = _BindingScope<Never Function(L)>;
```

This supersedes the earlier record proposal and its private-brand discussion.
The current private final carrier preserves nominal authority and
contravariance without a forgeable structural record. See
[ADR 0001](adr/0001-scope-bound-contravariant-either-effect.md).

The earlier concern about adding `.bind` to every nullable value was also
resolved conservatively: no `BindNullableValueExtension` is public. Nullable
values are handled explicitly through `effect.ensureNotNull(value, orLeft)` or
`nullable ?? effect.raise(error)`.

### The cost model

On a `Left` or `raise`, the binding implementation performs throw, stack
unwinding, and catch. Explicit `flatMap` does not require that control-flow
exception. This makes binding mechanically more expensive on the
short-circuit path.

The repository has no benchmark that quantifies the difference, so it would
be inaccurate to promise that the overhead is negligible. A reasonable usage
rule is:

- prefer `binding` / `futureBinding` where readability dominates, especially
  I/O-heavy Repository, UseCase, API, and database flows;
- consider explicit composition in CPU hot loops where `Left` is expected
  frequently as ordinary control flow; and
- add a benchmark before making performance claims in public documentation.

Broad `try`/`catch` inside a binding block remains discouraged. Dart permits
user code to catch the internal signal even though the library detects the
simple swallow-and-return case. Code should use the supplied
exception-to-`Either` helpers and never intentionally catch `ControlError`.

## Current strengths beyond binding

### API evolution discipline

Recent naming alignment introduced canonical APIs while retaining deprecated
aliases, compatibility tests, and migration notes. The repository also has a
documented variance review rule and an API-rename workflow. This is a stronger
maintenance posture than merely accumulating convenience methods.

### Targeted type-system hardening

`getOrDefault`, `combine`, `flatten`, and `merge` use generic extensions and
direct pattern matching where an instance boundary would be unsafe. The
`EitherEffect` design has compiler regression fixtures for contravariant
narrowing, rejected widening, and rejected external construction.

### CI and regression coverage

The main workflow runs all tests across stable, beta, and the Dart 3.0.0 lower
SDK bound. Stable additionally runs analysis, formatting, and coverage export.
Binding tests cover nesting, async lifetime, escaped capabilities, widened
runtime subtypes, and intercepted short-circuits.

The exact coverage percentage and the old counts of open/closed PRs in the
conversation were point-in-time metrics, not durable design facts. Refresh
them from GitHub/Codecov whenever they are needed for release or marketing
copy. Renovate-only PR activity likewise says little about architecture.

## Remaining risks and improvement roadmap

### Priority 0: finish the variance audit

[`docs/either-variance-safety.md`](either-variance-safety.md) explicitly says
its rule does not imply every existing API is safe. The following current
instance methods still place a covariant class type parameter in an unsafe
callback-produced position:

```dart
flatMap
getOrElse // deprecated, but still callable
getOrHandle
handleError
handleErrorWith
```

A consumer probe against current `master` reproduced `_TypeError` for
`flatMap`, `getOrHandle`, `handleError`, and `handleErrorWith` when an
analyzer-valid widened `Right<Never, int>` was viewed as
`Either<String, num>`. The failure happens at the virtual method boundary,
potentially before the branch or method body can protect the call.

This is the highest-value correctness work remaining:

1. Audit every public `Either<L, R>` instance signature, not only the methods
   already suspected.
2. Add widened `Left<L, Never>`, `Right<Never, R>`, and subtype-to-supertype
   regression fixtures for each unsafe shape.
3. In `2.x`, introduce safe canonical operations as generic extensions or
   top-level functions using direct pattern matching; retain old methods as
   deprecated compatibility paths where Dart name resolution permits it.
4. Reserve removal or reclamation of conflicting canonical names for the next
   major version.
5. Do not "fix" only the method body: runtime argument checks may fail before
   it executes.

### Priority 0: make parallel short-circuit semantics exact

`parSequenceN` currently maps every supplied function into `Future.wait` with
`eagerError: true`. A `Left` becomes a token-scoped `ControlError`, allowing
the returned result to complete early. This short-circuits the **result**, not
the underlying work:

- Dart `Future` has no built-in cancellation;
- already-running tasks continue after the first observed `Left`;
- with the current semaphore, queued `withPermit` calls remain queued and can
  start after a permit is released, even after the result has completed; and
- "first Left" means the first one observed by completion, not necessarily the
  first function in input order.

The existing docs say the operation short-circuits but do not state these
side-effect semantics. The existing tests assert the early result but do not
wait afterward to prove what happens to queued or running work.

Recommended sequence:

1. Document the current contract explicitly: result completion is early;
   running work is not cancelled; queued work may still start.
2. Add deterministic tests for result timing, input-order result collection,
   completion-order failure, running-task continuation, and queued-task start
   after failure.
3. Replace the eager `Future.wait` scheduling with a worker pool if the desired
   contract is "do not dequeue new work after the first observed `Left`".
   Running tasks still cannot be cancelled without cooperation.
4. If both behaviors are valuable, use an explicit option such as
   `startNewTasksAfterLeft: false` or a separately named API rather than
   overloading the word "short-circuit".
5. Treat true cancellation as a separate cooperative capability; do not imply
   that an early `Either` result cancels an HTTP request or arbitrary future.

### Priority 1: add typed nullable construction

The current `Either.fromNullable<R>` returns `Either<void, R>` and uses
`Left(null)`. This is convenient but often too weak for a domain boundary,
where a missing value should become a typed failure.

Add a non-breaking companion API, for example:

```dart
static Either<L, R> fromNullableOr<L, R extends Object>(
  R? value,
  L Function() ifNull,
)
```

Reasonable names from the earlier discussion are `fromNullableOr`,
`fromNullableWith`, or `fromNullableLeft`. Dart has no overloads, so changing
the existing signature under the same name is not a `2.x` option.

### Priority 1: make exception capture selective

`catchError`, `catchFutureError`, and `catchStreamError` currently catch
`Object`, except that their internal guard rethrows `ControlError`. This means
`StateError`, `TypeError`, `AssertionError`, and application exceptions are all
eligible for mapping if they reach the helper.

Teams often want to recover only from an expected exception class. Consider a
non-breaking predicate:

```dart
Either.catchError(
  mapper,
  block,
  test: (error) => error is FormatException,
)
```

or a typed API such as `catchOnly<FormatException, L, R>`. The internal control
signal must always be rethrown before any user predicate or mapper runs. Add
regressions proving that `ControlError` cannot be converted to `Left` by each
sync, future, and stream helper.

### Priority 2: decide the collection return strategy

`BuiltList` provides immutability and stable collection semantics, but it also
adds a runtime dependency and exposes a more FP-specific type to consumers.
Changing existing return types is breaking. Available paths are:

- keep `BuiltList` and state clearly that immutable collections are an
  intentional part of the package;
- add `sequenceList`, `traverseList`, and parallel `List` variants returning
  `List.unmodifiable`; or
- change the defaults only in a major release.

This is a product-positioning choice, not an automatic cleanup. Measure the
dependency and migration cost before deciding.

### Priority 2: add semantic laws and package gates

High line coverage is useful but does not establish algebraic laws or
lower-bound compatibility. Add explicit tests for:

- functor identity and composition;
- monad left identity, right identity, and associativity;
- `bimap` identity and composition;
- `swap().swap()` identity;
- `sequence` and `traverse` order preservation;
- parallel traversal result-order preservation;
- equivalence between binding and an explicit `flatMap` chain for success and
  the first `Left`; and
- the variance and parallel edge cases described above.

Add CI or release gates for:

```text
dart pub downgrade
dart test
dart pub publish --dry-run
dart doc
pana .
```

The current CI already runs the full suite and collects coverage; this work is
about semantic confidence, lower-bound support, documentation generation, and
package quality rather than merely increasing a percentage.

### Operational risk: community and bus factor

A small maintainer/community footprint is a legitimate adoption concern, but
it is not a defect that can be inferred from `Either` implementation code.
Track it separately through release cadence, issue responsiveness, contributor
distribution, and succession/documentation practices. Do not mix it with the
technical correctness verdict or quote stale PR counts as evidence.

## Test coverage matrix for the roadmap

| Area | Existing evidence | Missing confidence |
|---|---|---|
| Basic `Either` operations | Broad unit coverage | Explicit law/property suite |
| Naming migration | Deprecated alias tests and migration docs | Major-version removal plan |
| `EitherEffect` variance | Safe narrowing and compile-fail widening fixtures | No known gap in the new carrier |
| Scope isolation | Nested sync/async token tests | Stress interleavings if runtime changes |
| Capability lifetime | Post-scope use throws `StateError` | More async race cases if APIs expand |
| Swallowed short-circuit | Sync and async interception tests | Helper-specific `ControlError` filtering tests |
| Legacy `Either` variance | Selected safe APIs have widened tests | Full audit and migrations for unsafe methods |
| Sequential traversal | Success, first `Left`, and large iterable tests | Explicit order laws |
| Parallel traversal | Concurrency limit, result order, early `Left` | Running/queued work after early result |
| Dependency bounds | Dart 3.0.0 SDK job | `dart pub downgrade` dependency job |
| Package health | Analyze, format, full tests, coverage | `dart doc`, dry-run publish, and `pana` |
| Binding performance | Mechanism is understood | Reproducible benchmark before public claims |

## Recommended next slice

Start with one variance-hardening slice, not another convenience API:

1. turn the four reproduced unsafe methods plus deprecated `getOrElse` into a
   complete signature audit;
2. capture analyzer-valid runtime failures as regression fixtures;
3. propose additive safe names and a `2.x` deprecation path using the
   repository's API-rename workflow; and
4. keep the parallel-semantics clarification as the next independent slice.

This follows the maturity level the library has reached. The question is no
longer whether `Left` and `Right` work. It is whether every public type boundary
and async edge case behaves predictably under the hardest valid Dart programs.
