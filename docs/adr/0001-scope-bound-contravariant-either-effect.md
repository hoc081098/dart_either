---
status: accepted
---

# Represent EitherEffect with a private scope and contravariant phantom marker

`EitherEffect<L>` is an alias to a library-private final binding scope whose
type argument is a phantom function type:

```dart
typedef EitherEffect<L> = _BindingScope<Never Function(L)>;
```

`_BindingScope<T>` is covariant in `T`, while `Never Function(L)` is
contravariant in `L`. Their composition makes `EitherEffect<L>` contravariant,
so Dart rejects the unsafe `EitherEffect<int>` to `EitherEffect<num>` widening.
The phantom type has no runtime value; the private scope itself owns the token,
lifecycle phase, and direct `Left`/`Right` binding implementation.

`BindEitherEffectExtension.bind` is declared in the same Dart library as the
scope and delegates to its private generic bind operation. This preserves
`effect.bind(either)` completion without exposing replaceable behavior. The
scope is final and has only a named private constructor. The constructor shape
is an invariant of this decision because a public typedef would forward an
unnamed constructor from its aliased class.

Token identity continues to isolate nested scopes. Each capability issued by
`binding` or `futureBinding` is closed when its synchronous or asynchronous
block settles.

## Compatibility boundary

This representation hardening targets a `2.x.y` release. Supported usage keeps
the same source shape and behavior: obtain an effect from `Either.binding` or
`Either.futureBinding`, then use `effect.bind(either)`, `either.bind(effect)`,
`eitherFuture.bind(effect)`, or `effect.raise(value)` within the owning scope.
`raise` is convenience syntax for short-circuiting with an available left value
without constructing a `Left` solely to bind it.

The source-compatibility exception is prefixed imports and selective imports
that omit `BindEitherEffectExtension`; keeping `effect.bind(either)` requires
importing that extension unprefixed.

Directly constructing, implementing, destructuring, or replacing the binding
behavior of `EitherEffect` was never part of the supported contract. Capturing
an effect and invoking it after its scope settles is also unsupported. Those
usages do not require compatibility aliases or a major-version migration.

## Considered options

- A nominal public `EitherEffect<L>` with a consuming instance method was
  rejected because Dart class type parameters are covariant. A widened
  receiver can fail its runtime argument check before `bind` executes.
- A generic function typedef was type-safe, but Dart completion did not offer
  its extension members after `effect.`.
- An unbranded record preserved completion and variance safety, but any caller
  could construct it with arbitrary binding behavior.
- A branded record prevented construction from nothing, but a caller holding
  an issued capability could copy its public brand and replace the public
  `bind` function.
- An authenticated brand-and-token record could reject replacement at runtime,
  but required structural fields, identity checks, and extra per-scope values.
- An extension type around a contravariant function was rejected because Dart
  requires its representation type parameter to occur covariantly.

## Consequences

- Safe narrowing, such as `EitherEffect<num>` to `EitherEffect<int>`, remains
  valid; unsafe widening is a compile-time error.
- Code outside the declaring library cannot construct, extend, implement, or
  replace the binding behavior of `EitherEffect`.
- Copying an issued capability copies the same scope reference. The copy shares
  its token and lifecycle and cannot create independent binding authority.
- Capturing the capability is syntactically possible, but invoking it after its
  scope closes throws `StateError`.
- The scope object is the capability. The design does not require a record
  envelope, generic bind closure, global registry, or runtime authenticity
  lookup.
- Dartdoc displays the private alias expansion
  `_BindingScope<Never Function(L)>`; this is an accepted documentation leak of
  an inaccessible implementation type.
