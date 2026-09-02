# `dart_either`: current strengths and improvement roadmap

This note distills an earlier discussion about the value proposition of
`dart_either` and the improvements that could make it more robust. It is not a
transcript or marketing copy. Every technical statement below was last
reconciled with the repository state on 2026-09-02.

The package currently declares version `2.3.0`. This repository state is
prepared for release; verify the registry before describing `2.3.0` as
published.

## Executive summary

The strongest proposition is not that `Either` itself is difficult to write.
`Left` and `Right` are the inexpensive part. The library's value is the
coherent application-facing surface around them: transformations, recovery,
nullable and exception bridges, async composition, collection traversal, and
direct-style `binding` scopes, backed by documentation and edge-case tests.

The current implementation is a credible focused alternative for projects
that want typed failure without importing a broader FP toolkit. Its most
distinctive feature is `Either.binding` / `Either.bindingAsync`: sequential
typed-failure code can retain ordinary Dart control flow (`await`, local
variables, `if`, and `return`) while short-circuiting on the first `Left`.

The code is stronger than the earlier conversation's snapshot in several
areas. `EitherEffect` is no longer the proposed forgeable structural record;
it is now an opaque, scope-bound, contravariant capability backed by a private
final class. Captured capabilities are revoked, intercepted short-circuits are
detected, `raise` is implemented, and the full test suite runs in CI.

The main remaining technical debt is not a lack of more convenience methods.
It is semantic precision:

1. migrate the five variance-unsafe legacy instance methods identified by the
   completed audit;
2. finish the remaining timing and running-work coverage for the now-defined
   parallel short-circuit contract;
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
  `isLeft`, `isRight`, `isLeftAnd`, and `isRightAnd`;
- transformation and composition with `map`, `mapLeft`, `flatMap`, `bimap`,
  `fold`, `combine`, `flatten`, `merge`, and `swap`;
- recovery and extraction with `getOrNull`, `leftOrNull`, `getOrDefault`,
  `getOrHandle`, `handleError`, and `handleErrorWith`;
- exception, `Future`, and `Stream` bridges through `tryCatch`,
  `tryCatchAsync`, `toEitherFuture`, and `toEitherStream`, with
  `registerFatalError` for app-wide rethrow policy;
- async chaining with `thenMapEither` and `thenFlatMapEither`;
- sequential and parallel collection operations through `sequence`,
  `traverse`, `parSequenceN`, and `parTraverseN`; and
- direct-style composition through `binding`, `bindingAsync`, `bind`,
  `bindFuture`, `ensure`, `ensureNotNull`, and `raise`.

`traverse` and `sequence` remain useful for batch validation or transforming a
collection of fallible operations. In ordinary Repository/UseCase code,
however, `binding` and `bindingAsync` are usually the more differentiating
feature because they remove nested `flatMap` while preserving explicit typed
failure.

### Direct-style typed failure

This is valid current syntax; `Future<Either<L, R>>.bind(effect)` is provided by
`BindEitherFutureExtension`:

```dart
final result = await Either.bindingAsync<AppError, Output>((effect) async {
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

- Every `binding` or `bindingAsync` call creates its own token. A boundary
  catches only a `ControlError` with the identical token, so nested scopes do
  not consume one another's short-circuit.
- `Right` values are unwrapped. `Left` and `raise` terminate only the owning
  binding scope.
- Ordinary exceptions and failed futures propagate unchanged. They are not
  silently converted to `Left`.
- Explicit conversion is available through `tryCatch`, `tryCatchAsync`,
  `toEitherFuture`, and `toEitherStream`. Their `ErrorMapper` receives both the
  object and its `StackTrace`.
- Those helpers call the internal `throwIfFatal` guard, which rethrows
  `ControlError` and types registered through `registerFatalError` instead of
  mapping them into a domain `Left`.
- The capability remains active across work returned from `bindingAsync`,
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

- prefer `binding` / `bindingAsync` where readability dominates, especially
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

### Priority 0: migrate variance-unsafe instance APIs

[`docs/either-variance-safety.md`](either-variance-safety.md) now classifies
every public instance member declared directly on `Either<L, R>`. Widened
regression tests cover the safe operations, and every canonical safe method is
marked only after its signature and implementation have been audited. The
following current instance methods still place a covariant class type parameter
in an unsafe callback-produced position:

```dart
flatMap
getOrElse // deprecated, but still callable
getOrHandle
handleError
handleErrorWith
```

A consumer probe against current `master` reproduced `_TypeError` for all five
methods when an analyzer-valid widened `Right<Never, int>` was viewed as
`Either<String, num>`; `flatMap` was also reproduced with a widened
`Left<String, Never>`. The failure happens at the virtual method boundary,
potentially before the branch or method body can protect the call.

Migrating these five methods is the highest-value correctness work remaining:

1. Preserve analyzer-valid widened receiver reproductions for each unsafe
   shape and use them as regression fixtures for replacement operations.
2. In `2.x`, introduce safe canonical operations as generic extensions or
   top-level functions using direct pattern matching; retain old methods as
   deprecated compatibility paths where Dart name resolution permits it.
3. Reserve removal or reclamation of conflicting canonical names for the next
   major version.
4. Do not "fix" only the method body: runtime argument checks may fail before
   it executes.

### Priority 0: make parallel short-circuit semantics exact

`parSequenceN` maps every supplied function into `Future.wait` with
`eagerError: true`. A `Left` becomes a token-scoped `ControlError`, allowing
the returned result to complete early. The executor records that signal before
releasing the task's semaphore permit. With a finite concurrency limit,
callbacks still waiting for a permit are then rejected without invoking the
supplied function.

This short-circuits the **result** and prevents queued supplied functions from
being invoked; it does not cancel underlying work:

- Dart `Future` has no built-in cancellation;
- already-running tasks continue after the first observed `Left`;
- queued `withPermit` wrappers still acquire and release permits so their
  futures can settle, but they reject with the recorded control signal before
  invoking their supplied functions;
- with `maxConcurrent: null`, every function starts before an asynchronous
  `Left` can be observed; and
- "first Left" means the first one observed by completion, not necessarily the
  first function in input order.

Completed in the current patch slice:

1. The public API and README state the queued-versus-running contract.
2. Deterministic tests prove that queued functions are not invoked after a
   `Left`, including when an ordinary future error completed the aggregate
   result before the `Left` was observed.

Remaining follow-up work:

1. Add explicit tests for result timing, running-task continuation,
   completion-order failure selection, and input-order result collection.
2. Consider a worker pool if avoiding the allocation and post-`Left` draining
   of one wrapper future per input becomes important. This is an efficiency
   change; it is not required to prevent queued supplied functions from being
   invoked.
3. Treat true cancellation as a separate cooperative capability; do not imply
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

`tryCatch`, `tryCatchAsync`, `toEitherFuture`, and `toEitherStream` catch
`Object`, except that their internal guard rethrows `ControlError` and types
registered through `registerFatalError`. This means `StateError`, `TypeError`,
`AssertionError`, and application exceptions remain eligible for mapping unless
the application registers a matching fatal type.

The global registration policy handles app-wide exclusions such as
cancellation exceptions. Teams may still want an individual call to recover
only from an expected exception class. Consider a non-breaking predicate:

```dart
Either.tryCatch(
  action: block,
  errorMapper: mapper,
  test: (error) => error is FormatException,
)
```

or a typed API such as `catchOnly<FormatException, L, R>`. The internal control
signal and registered fatal errors must always be rethrown before any user
predicate or mapper runs.

#### Recommended Flutter application policy

When an application's failure type contains domain, infrastructure, and
last-resort unexpected cases, name it `AppFailure` rather than `DomainError`.
The `Left` type then honestly describes every recoverable failure that the
application intentionally exposes to presentation code:

```text
Future<Either<AppFailure, A>>
├── Right<A>                  success
├── Left<AppFailure>         recoverable application failure
└── Future error             fatal or control-flow failure
```

Register the base Dart [Error](https://api.dart.dev/dart-core/Error-class.html)
type instead of enumerating `StateError`, `TypeError`, `AssertionError`, and
the other programming-error subtypes individually:

```dart
void configureErrorCapture() {
  Either.registerFatalError<Error>();
  Either.registerFatalError<AppCancellationException>();
}
```

Registration uses subtype matching, so `Error` covers all of its subtypes.
Do not register the base `Exception` type: recoverable exceptions such as
network, timeout, and invalid-response failures must remain eligible for
specific `AppFailure` mapping. Internal `ControlError` values are always
re-thrown and require no registration. Register application-specific
cancellation and other control-flow exceptions separately.

Use this mapping policy:

| Failure category | Debug | Release |
|---|---|---|
| Registered `Error` or control-flow type | Propagate | Propagate |
| Known recoverable exception | Map to a specific `AppFailure` | Map to a specific `AppFailure` |
| Unexpected non-fatal error | Log/report, then rethrow with its original stack trace | Log/report, then return `AppFailure.unknown` |

An unknown case should retain the original error and stack trace for
diagnostics, but it must not be assumed to be retryable. For example, a remote
write may have succeeded even if decoding its response failed. Avoid duplicate
reporting when a debug rethrow also reaches a global error handler.

In this API, “fatal” means that an error must bypass `ErrorMapper` and remain in
the outer error channel. It does not necessarily mean that the process must
terminate: cancellation still propagates to its owning lifecycle boundary, and
a Flutter global error handler ultimately decides how an otherwise unhandled
error is reported or terminated.

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
| Parallel traversal | Concurrency limit, result order, early `Left`, queued functions rejected after `Left` | Explicit running-task continuation and timing laws |
| Dependency bounds | Dart 3.0.0 SDK job | `dart pub downgrade` dependency job |
| Package health | Analyze, format, full tests, coverage | `dart doc`, dry-run publish, and `pana` |
| Binding performance | Mechanism is understood | Reproducible benchmark before public claims |

## Recommended next slice

Continue with one variance-migration slice, not another convenience API:

1. capture analyzer-valid runtime failures for the five classified unsafe
   methods as replacement regression fixtures;
2. propose additive safe names and a `2.x` deprecation path using the
   repository's API-rename workflow; and
3. keep the remaining parallel timing and running-work tests as the next
   independent slice.

This follows the maturity level the library has reached. The question is no
longer whether `Left` and `Right` work. It is whether every public type boundary
and async edge case behaves predictably under the hardest valid Dart programs.
