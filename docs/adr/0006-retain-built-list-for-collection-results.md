---
status: accepted
---

# Retain BuiltList for collection results

`Either.sequence`, `Either.traverse`, `Either.parSequenceN`, and
`Either.parTraverseN` retain `BuiltList<R>` as their successful result type.
Immutable collection structure and equality and hashing by contents are
intentional parts of this contract. The current 3.x plan retains this choice.

## Rationale

`BuiltList` exposes a collection interface without mutation methods. This
expresses immutability in the result type, while an SDK `List` exposes methods
such as `add`, `remove`, and `[]=` even when its implementation rejects them.

`Either` delegates equality and hashing to its active payload, as recorded in
[ADR 0004](0004-define-either-value-equality-and-branch-aware-hashing.md).
`BuiltList` compares its elements and derives its hash from their hash codes.
Two independent successful traversals can therefore compare equal when their
ordered elements compare equal. Replacing these results with SDK lists would
also change equality behavior, because those lists use identity equality by
default.

The implementations already collect results through `ListBuilder` before
publishing the built value. Retaining this design accepts `built_collection`
as a runtime dependency and public type dependency in exchange for these
semantics. Performance claims require measurements for the target workload.

Collection immutability does not freeze the elements. Callers remain
responsible for their elements' equality and hashing contracts, especially
when collection values are used as map keys or set members.

## SDK collection interoperability

`BuiltList` implements `Iterable`, so callers can pass it directly to APIs
accepting `Iterable`. For an API requiring `List`, use `.asList()`:

```dart
final Either<String, BuiltList<int>> sequenced = Either.sequence([
  Either.right(1),
  Either.right(2),
]);
final Either<String, List<int>> listCompatible =
    sequenced.map((values) => values.asList());
```

`.asList()` returns an unmodifiable SDK list; mutation attempts throw
`UnsupportedError`. This conversion does not promise to avoid copying:
`built_collection` 5.1.1 implements it with `List.unmodifiable`.

If a receiving API needs to modify the list, use `.toList()` instead. Its
documented copy-on-write behavior allows modifications without changing the
original `BuiltList`. Neither conversion freezes mutable elements or retains
`BuiltList`'s equality by contents on the returned SDK list.

## Considered options

- Changing the existing return types to `List` would remove an intentional
  immutable interface and change payload equality. It would also require a
  breaking release and consumer migration.
- Adding parallel `sequenceList`, `traverseList`, and async variants would
  duplicate four operations for a conversion already available through `map`
  and `.asList()`.
- Returning `Iterable` would hide indexed access, `BuiltList` equality, and
  explicit SDK conversion behind a less informative static type.

## Consequences

- All four collection operations keep one canonical result type and accept
  their existing iterable inputs.
- README, Dartdocs, and runnable examples explain SDK `List` compatibility
  at the consumer boundary.
- Removing `built_collection` or changing the result type requires a new
  decision covering immutability, equality, and source compatibility.

## References

- [Built collections design](https://pub.dev/packages/built_collection).
- [BuiltList API](https://pub.dev/documentation/built_collection/latest/built_collection/BuiltList-class.html).
- [SDK List equality](https://api.dart.dev/dart-core/List/operator_equals.html).
