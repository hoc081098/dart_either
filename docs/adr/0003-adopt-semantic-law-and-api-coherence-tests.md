---
status: accepted
---

# Adopt semantic law and API coherence tests

`dart_either` treats the algebraic laws of its public right-biased `Either`
operations as the strongest semantic invariants within their applicable
domain. Add a dedicated test suite for those laws and for coherence between
the package's equivalent composition styles. The suite protects existing
public behavior; it does not introduce type classes or claim abstractions that
the package does not expose.

For the laws below, fix the left type and treat `Either<L, A>` as the type
constructor under test. `Either<L, A>.right(value)` is `pure`. Equality means
the public `Either.operator ==`, and every function used in a law equation is
pure and total. Object identity, callback invocation counts, thrown errors,
stack traces, timing, concurrency, and cancellation remain operational
contracts covered by targeted tests rather than algebraic laws.

## Accepted laws and coherence

The algebraic suite covers:

- Functor identity and composition for `map`.
- Monad left identity, right identity, and associativity for `flatMap`.
- Bifunctor identity and composition for `bimap`.
- Coherence of `bimap(identity, rightMapper)` with `map(rightMapper)` and
  `bimap(leftMapper, identity)` with `mapLeft(leftMapper)`.
- The `swap().swap()` involution and coherence between `swap` and `bimap`.
- Coherence of `map(f)` with
  `flatMap((value) => Either.right(f(value)))`.

The package-specific suite also covers:

- `traverse(values, mapper)` is equivalent to
  `sequence(values.map(mapper))`.
- Traversing with a mapper that returns only `Right` values is equivalent to
  mapping the input in order and wrapping the resulting `BuiltList` in
  `Right`.
- `Either.binding` is equivalent to the corresponding explicit `flatMap`
  pipeline for success, a left at the first step, and a left at a later step.
- `Either.bindingAsync` is equivalent to the corresponding
  `thenFlatMapEither` and `thenMapEither` pipeline for the same outcomes. Its
  cases include a real asynchronous suspension rather than only synchronous
  values wrapped in a `Future`.
- Within both synchronous and asynchronous binding scopes,
  `bind(Left(error))` is equivalent to `raise(error)`, `ensure` either
  continues or raises according to its condition, and `ensureNotNull` either
  returns its non-null value or raises for `null`.

These are laws of canonical APIs only. Deprecated aliases continue to require
compatibility and delegation coverage in `test/deprecated_aliases_test.dart`,
but the law suite does not repeat every law through those aliases.

## Scope boundary

The package has no public `ap` operation or higher-kinded Applicative
abstraction, so this decision does not add Applicative law tests. `combine` is
not treated as `ap`: it combines equal right types and can combine two left
values through caller-supplied operations.

Likewise, `Either.traverse` and `Either.sequence` are concrete operations for
an `Iterable` and the `Either` effect, not a generic Traversable instance.
Their concrete coherence and ordering properties are tested without claiming
the generic Traversable naturality or composition laws. Existing targeted
tests remain authoritative for encounter order, first-left short-circuiting,
parallel result order, and parallel failure behavior; the law suite does not
duplicate those scenarios.

Algebraic-law precedence is intentionally scoped. A conflicting example or
result-oriented test must conform to an accepted law, but a law must not be
used to override public signatures, source compatibility, or operational
contracts outside pure and total evaluation. Removing or changing an accepted
law requires a new architectural decision and an explicit breaking-release
assessment.

## Test strategy

Use deterministic finite-domain matrices of representative `Left` and `Right`
values and pure functions, including functions that return `Right` and
functions that return `Left` at each composition stage. Do not add a
property-testing dependency for this initial suite. Reconsider generators and
shrinking only if the public algebra or value model becomes complex enough to
justify their maintenance cost.

Keep the suite in three files organized by semantic boundary:

```text
test/laws/
├── either_algebraic_laws_test.dart
├── either_traversal_coherence_test.dart
└── either_binding_coherence_test.dart
```

These tests run through the normal `dart test` command and are hard release
gates on every supported CI SDK job, including stable, beta, and the Dart 3.0.0
lower bound. A failing law is a semantic regression by default; its expectation
must not be rewritten merely to accommodate an implementation change.

## Considered options

- Claiming lawful Functor, Applicative, Monad, and Traversable type classes was
  rejected because Dart has no higher-kinded type parameters and this package
  does not expose `ap` or a generic traversal abstraction.
- Randomized property testing was deferred because the two-branch `Either`
  model and current operations can be exercised with small, deterministic
  cross-product matrices without another dependency or nondeterministic
  failure reproduction.
- Keeping all coverage in method-specific tests was rejected because laws such
  as Functor composition, `bimap` coherence, and binding equivalence express
  relationships across multiple public operations.

## Consequences

- Future optimizations and refactors must preserve the accepted algebraic and
  coherence relationships in addition to their method-specific behavior.
- The test names and failure output distinguish formal algebraic laws from
  package-specific coherence properties.
- Operational regressions remain visible in focused tests instead of being
  obscured by side effects inside otherwise pure law functions.
- Package-quality automation such as dependency downgrade, Dartdoc validation,
  publish dry-run, and `pana` remains a separate roadmap slice.
