---
status: accepted
---

# Represent EitherEffect as a scope-bound contravariant capability

`EitherEffect<L>` is a one-field named record containing a generic `bind`
function. This shape makes `L` contravariant, so Dart rejects the unsafe
`EitherEffect<int>` to `EitherEffect<num>` widening that a nominal generic
class permits, while the named field keeps `effect.bind(...)` discoverable in
IDE completion. Token identity isolates nested scopes, and each capability
issued by `binding` or `futureBinding` is revoked when its synchronous or
asynchronous block settles.

## Considered options

- A nominal `EitherEffect<L>` with a consuming `bind` method was rejected
  because Dart class type parameters are covariant and the widened receiver can
  fail at runtime before the method body executes.
- A generic function typedef was type-safe, but Dart completion did not offer
  its extension members after `effect.`.
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
- The typedef is structural, so callers can construct matching records.
  Scope isolation and revocation are guarantees of capabilities issued by
  `binding` and `futureBinding`, not of arbitrary user-created records.
- The record envelope can add one allocation per binding scope; optimizer
  elimination is not part of the interface contract.
