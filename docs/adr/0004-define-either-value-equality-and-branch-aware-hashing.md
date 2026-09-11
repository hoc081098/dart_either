---
status: accepted
---

# Define Either value equality and branch-aware hashing

`Either` uses value equality based on its active branch and payload, not on its
reified generic type arguments. Hashing must reflect the same semantics by
combining the active branch with the payload hash. This keeps equality lawful
across generic widening and value-preserving transformations while avoiding the
systematic `Left(value)`/`Right(value)` collisions caused by payload-only
hashing.

## Equality semantics

Two `Either` values are equal when either condition holds:

- They are identical.
- They occupy the same branch and their active payloads are equal according to
  the payload's `operator ==`.

Generic type arguments and `runtimeType` do not participate. A `Left` is never
equal to a `Right`, even when their payloads are equal. Equality delegates to
the payload rather than adding a payload runtime-type check or performing deep
equality. For example:

```dart
Right<Never, int>(1) == Right<Never, num>(1)      // true
Left<int, Never>(1) == Left<num, String>(1)       // true
Right<Never, int>(1) == Right<Never, double>(1.0) // true
Left<Object, Object>(1) == Right<Object, Object>(1) // false
```

The identity fast path preserves reflexivity when a payload is not reflexive,
as with `double.nan`: an `Either` instance remains equal to itself, while two
distinct instances containing `double.nan` remain unequal.

This definition intentionally inherits the payload's equality contract. If a
payload implements asymmetric, non-transitive, or otherwise invalid equality,
`Either` does not attempt to repair it.

## Hashing semantics

`hashCode` follows computed-on-read semantics and derives its value from two
inputs:

1. A branch-specific discriminator that is different for `Left` and `Right`.
2. The active payload's current `hashCode`.

An implementation may use `Object.hash(_leftHashSeed, value)` and
`Object.hash(_rightHashSeed, value)`, but the particular seeds and combining
algorithm are private implementation details. The discriminator must not use
the instance's reified generic arguments or `runtimeType`, because values that
are equal across generic instantiations must have equal hash codes.

Different branch discriminators reduce systematic cross-branch collisions;
they do not guarantee that every `Left(value)` and `Right(value)` pair has
different final hash codes. Hash collisions between unequal values remain
valid. The stable contract is only that equal `Either` values have equal hash
codes.

The computed hash is not cached. Mutable payloads can therefore change an
`Either`'s hash after construction, just as they can change their own hash.
Using such a value as a `Set` member or `Map` key while mutating it remains the
caller's responsibility.

Exact hash values are not public API and must not be persisted or reused across
processes or package versions.

## Compatibility and verification

The equality definition codifies existing behavior. Replacing payload-only
hashing with branch-aware hashing is a compatible patch-release change: it
changes bucket distribution without changing equality or the Dart
`Object.hashCode` contract.

The implementation patch must cover:

- Reflexivity through the identity fast path, including `double.nan`.
- Same-branch equality and equal hashes across generic instantiations.
- Delegation to payload equality across payload runtime types.
- Cross-branch inequality.
- `Set` and `Map` behavior for equal and unequal `Either` values.
- A representative payload matrix proving that `Left` and `Right` hashes are
  not systematically identical, without asserting pairwise non-collision or
  exact hash values.

## Considered options

- Comparing reified generic arguments or exact `runtimeType` was rejected
  because covariant widening can make such checks asymmetric, and
  value-preserving operations can reconstruct an equal value with different
  runtime type arguments.
- Comparing only payloads was rejected because it would make `Left(value)` and
  `Right(value)` equal despite representing different alternatives.
- Returning only `value.hashCode` was rejected because it makes every
  same-payload cross-branch pair collide even though those values are unequal.
- Guaranteeing distinct final hashes for every cross-branch pair was rejected
  because unequal objects may collide and such a promise would unnecessarily
  constrain the combining algorithm.
- Caching the hash at construction was rejected because it cannot repair a
  mutable payload's equality contract and can leave equal wrappers with hashes
  captured from different payload states.

## Consequences

- Equality remains stable across generic widening and across the algebraic-law
  comparisons established by
  [ADR 0003](0003-adopt-semantic-law-and-api-coherence-tests.md).
- Equal `Either` values behave as one key in hash collections; `Left` and
  `Right` remain distinct keys even if an incidental hash collision occurs.
- Consumers must supply payloads with lawful, collection-safe equality and
  hashing when they use `Either` in `Set` or as a `Map` key.
- A future change to `Either` equality requires a new architectural decision
  and a breaking-release assessment. Hash implementation details may change in
  compatible releases as long as this equality/hash contract is preserved.
