---
status: accepted
---

# Add catchOnly as a selective ErrorMapper adapter

`dart_either` will add one top-level `catchOnly` function that adapts a typed
error mapper to the existing `ErrorMapper<L>` interface:

```dart
ErrorMapper<L> catchOnly<E extends Object, L>(
  L Function(E error, StackTrace stackTrace) errorMapper,
)
```

Place `catchOnly` next to `ErrorMapper` in `lib/src/dart_either.dart`. The
package barrel already exports that source file, so no additional public
module or export seam is required.

The existing `ErrorMapper<L>` seam is shared by `Either.tryCatch`,
`Either.tryCatchAsync`, `Future.toEitherFuture`, and `Stream.toEitherStream`.
Adding selective capture at that seam gives all four canonical operations the
same type-directed behavior without introducing a parallel operation for each
execution form.

## Behavioral contract

`catchOnly` is an adapter intended for the `errorMapper` parameter of the four
canonical capture operations. Those operations retain ownership of error
capture and fatal-error policy. They must invoke `throwIfFatal` before the
adapter sees an error, so `ControlError` and errors matching
`Either.registerFatalError` remain in the outer error channel with their
original object and stack trace even when they satisfy `E`.

For a non-fatal error passed to the adapter:

- `error is E` matches `E` and every subtype of `E`.
- A match invokes the typed `errorMapper` exactly once and returns its `L`.
- A non-match invokes no mapper and is rethrown with
  `Error.throwWithStackTrace(error, stackTrace)`.
- An error thrown by the typed mapper propagates unchanged. The same capture
  operation does not catch it again and convert it to a `Left`.

`E = Object` is valid. For non-fatal errors,
`catchOnly<Object, L>(errorMapper)` is coherent with passing an equivalent
`ErrorMapper<L>` directly.

Calling the returned function directly is not an error-capture operation and
does not apply the package's fatal-error policy. The fatal-before-selection
guarantee applies when the adapter is consumed by one of the canonical capture
operations.

Deprecated `catchError`, `catchFutureError`, and `catchStreamError` aliases may
continue to work with the adapter through their delegation to canonical
operations. Documentation and examples must use the canonical operations and
must not expand the recommended deprecated surface.

The upstream behavior and the differences between Arrow's constructor shape
and this Dart adapter are recorded in the
[Arrow selective catch reference](../arrow-selective-catch-reference.md).

## Considered options

- A `tryCatchOnly<E, L, R>` family was rejected because equivalent sync,
  async, Future, and Stream entry points would repeat one selection interface
  across four execution forms. A selective factory constructor is also not
  possible because Dart constructors cannot introduce the additional local
  type parameter `E`; it would need to be a static method.
- Adding a predicate to every existing capture operation was rejected because
  a predicate over `Object` does not narrow the mapper's parameter type. It
  would also enlarge four established interfaces and allow predicate and
  mapper selection to drift apart.
- Arrow's `catchOrThrow<E, R>` shape was not copied because it places the
  caught error itself in `Left`. `dart_either` already uses
  `ErrorMapper<L>` to construct a domain-specific left value with access to the
  original stack trace.
- A public `ErrorCapture<E, L>` policy object was rejected because it would add
  a nominal type and multiple methods before a concrete consumer requires a
  reusable policy or value-level selection.
- Arbitrary predicates and overloads are deferred. The accepted interface is
  type-directed only; reconsider broader selection when a concrete case cannot
  be represented by an error type.

## Consequences

- One additive public function enables selective capture through all four
  canonical execution forms while leaving their signatures unchanged.
- Type selection, typed mapping, and non-match rethrow behavior remain local to
  one implementation.
- Callers must type the mapper's error parameter or provide explicit generic
  arguments when inference would otherwise choose a broader `E`.
- Tests must cover exact-type and subtype matches, `E = Object`, non-matching
  error identity and stack preservation, fatal-before-selection ordering,
  mapper invocation count, mapper-error propagation, and composition with the
  sync, async, Future, and Stream capture operations.
