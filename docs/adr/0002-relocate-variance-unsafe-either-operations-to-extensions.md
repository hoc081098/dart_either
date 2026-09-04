---
status: accepted
---

# Relocate variance-unsafe Either operations to generic extensions in 2.4.0

Dart permits covariant class type parameters in instance-method input
positions by inserting runtime argument checks at the virtual method boundary.
For five existing `Either<L, R>` instance operations, analyzer-valid widened
receivers can therefore throw `_TypeError` before the method body executes. In
`2.4.0`, remove those instance declarations and expose the same operations as
named generic extensions so their inputs are checked against the receiver's
static type arguments instead.

The relocated operations and public extension types are:

| Operation | Extension type |
|---|---|
| `flatMap` | `FlatMapEitherExtension<L, R>` |
| `getOrElse` | `GetOrElseEitherExtension<L, R>` |
| `getOrHandle` | `GetOrHandleEitherExtension<L, R>` |
| `handleError` | `HandleErrorEitherExtension<L, R>` |
| `handleErrorWith` | `HandleErrorWithEitherExtension<L, R>` |

Each extension implements its operation with direct `Left`/`Right` pattern
matching. It must not delegate to an unsafe virtual member or to a shared
helper introduced only to avoid repeating the two branches. The extension may
carry the internal `@covarianceSafe` marker only after widened regression
coverage proves the new call boundary.

## Behavioral invariants

Relocation preserves the existing name, signature, annotations, callback
timing, error propagation, result, and identity semantics:

- `flatMap` skips its callback for `Left`, invokes it exactly once for `Right`,
  and does not catch callback errors.
- `getOrElse` and `getOrHandle` remain lazy and invoke their fallback exactly
  once only for `Left`.
- `handleError` returns the identical `Right` instance and invokes its callback
  exactly once only for `Left`.
- `handleErrorWith` skips its callback for `Right` and returns an equivalent
  `Right` with the new left type without promising instance identity.
- No relocated operation catches an error thrown by its callback.

The deprecated zero-argument `getOrElse(R Function())` remains deprecated in
`2.x`. `getOrHandle(R Function(L))` retains its current non-deprecated status
and semantics. Their `3.0.0` replacement plan remains the one recorded in the
[fallback migration details](../api-naming-alignment.md#fallback-migration-details):
remove `getOrHandle` and replace the legacy `getOrElse` signature with the
left-aware `getOrElse(R Function(L))` generic extension.

## Source and test organization

Every public extension on an `Either` receiver lives in its own method-named
file under `lib/src/either_extensions/`, including the extensions that existed
before this relocation. `lib/src/either_extensions.dart` remains an aggregator
that exports those files, and the package barrel continues to export only that
aggregator.

Tests mirror the source layout under `test/either_extensions/`. Each operation
is covered through its public interface for normal semantics, callback
invocation count, relevant identity behavior, widened `Left<L, Never>` and
`Right<Never, R>` receivers, and subtype widening such as `int` to `num`.
Deprecated alias coverage remains in `test/deprecated_aliases_test.dart`.

## Compatibility boundary

The supported import seam is:

```dart
import 'package:dart_either/dart_either.dart';
```

For a statically typed receiver with the named extension in scope, normal call
syntax such as `either.flatMap(...)` remains unchanged. A selective import must
include the relevant extension type. Calls through a `dynamic` receiver no
longer dispatch to these operations after their instance declarations are
removed. Direct imports from `package:dart_either/src/...` are outside the
compatibility contract even though the aggregator is retained to reduce
incidental breakage.

Shipping this relocation in `2.4.0` is a deliberate, narrowly scoped
compatibility exception for these five operations. It is not a general policy
that `2.x` releases may freely introduce source-breaking changes. Removing the
known analyzer-valid runtime failure is prioritized over waiting for `3.0.0`,
while the dominant statically typed dot-call syntax remains unchanged.

## Considered options

- Waiting until `3.0.0` would avoid a compatibility exception but would retain
  a known runtime type failure through the rest of `2.x`.
- Adding same-name extensions while retaining the instance members would not
  fix ordinary calls because instance members take precedence over extensions.
- Adding top-level functions or temporary safe names would expand the public
  interface and force a second migration without preserving normal dot-call
  syntax.
- Moving only a subset would leave other operations identified by the same
  completed variance audit unsafe.
- Sharing an internal two-branch helper would add coupling between otherwise
  self-contained operation files without hiding meaningful complexity.

## Consequences

- No public instance member identified by the completed audit remains
  variance-unsafe after `2.4.0`.
- The package keeps familiar statically typed call syntax while making widened
  receivers safe at the extension call seam.
- Selective-import users must import the named extension types, and dynamic
  dispatch users must migrate to a statically typed receiver.
- Public Dartdoc links for the five operations move from `Either` pages to
  their extension pages; README, examples, changelog, repository docs, and all
  project usages must be updated in the same implementation change.
