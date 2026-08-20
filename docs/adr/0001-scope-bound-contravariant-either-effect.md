---
status: accepted
---

# Represent EitherEffect as a scope-bound contravariant capability

`EitherEffect<L>` is a branded named record containing a generic `bind`
function and a private-typed `brand` marker. The generic function makes `L`
contravariant, so Dart rejects the unsafe `EitherEffect<int>` to
`EitherEffect<num>` widening that a nominal generic class permits. The named
`bind` field keeps `effect.bind(...)` discoverable in IDE completion, while the
brand prevents code that has never received a package-issued marker from
independently constructing a matching record. Token identity isolates nested
scopes, and each capability issued by `binding` or `futureBinding` is revoked
when its synchronous or asynchronous block settles.

## Considered options

- A nominal `EitherEffect<L>` with a consuming `bind` method was rejected
  because Dart class type parameters are covariant and the widened receiver can
  fail at runtime before the method body executes.
- A generic function typedef was type-safe, but Dart completion did not offer
  its extension members after `effect.`.
- An unbranded named record preserved completion and variance safety, but any
  caller could construct one with arbitrary `bind` behavior.
- An extension type around the function was rejected because Dart forbids its
  type parameter in a non-covariant representation position.

## Consequences

- Safe narrowing, such as `EitherEffect<num>` to `EitherEffect<int>`, remains
  valid; unsafe widening is a compile-time error.
- `effect.bind(either)`, `either.bind(effect)`, and
  `eitherFuture.bind(effect)` remain the supported binding forms. Direct
  function invocation is not supported.
- Capturing the capability is syntactically possible, but invoking it after
  its scope closes throws `StateError`.
- The private brand type prevents independent record construction. Dart record
  field names cannot be private, however, so code already holding an issued
  capability can read and copy its `brand` marker. The brand is a type-level
  construction barrier, not a runtime authenticity check. Callers must treat
  it as an implementation detail; scope isolation and revocation are
  guarantees only of the original capabilities supplied by `binding` and
  `futureBinding`.
- The record envelope can add one allocation per binding scope; optimizer
  elimination is not part of the interface contract.
