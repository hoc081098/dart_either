# Either variance safety

This document defines the variance rules for public APIs on `Either<L, R>`.
Use it when adding an operation, moving an operation between the class and an
extension, or reviewing an implementation that delegates to another method.

This is a design and testing rule. It does not imply that every existing API
already satisfies the rule.

## Why this matters in Dart

Dart does not expose Kotlin-style declaration-site `in` and `out` modifiers.
Generic class type arguments are nevertheless covariant, so conceptually this
package's type behaves like Kotlin's `Either<out L, out R>`:

```text
L1 <: L2 and R1 <: R2
implies
Either<L1, R1> <: Either<L2, R2>
```

These assignments are therefore valid:

```dart
final Either<String, int> widenedLeft =
    const Left<String, Never>('error');

final Either<String, num> widenedRight =
    const Right<Never, int>(1);
```

The static types are widened, but the runtime objects still carry the narrower
type arguments `Left<String, Never>` and `Right<Never, int>`.

Unlike Kotlin, Dart permits a covariant class type parameter in an instance
method input position. Dart preserves type safety by inserting runtime argument
checks at the virtual method boundary. Those checks use the runtime receiver's
narrow type arguments and happen before the method body executes.

For example, this signature is unsafe as an instance member:

```dart
R getOrDefault(R defaultValue);
```

The following call is accepted using the static type, but the runtime receiver
checks the argument as `Never`:

```dart
final Either<String, int> either =
    const Left<String, Never>('error');

either.getOrDefault(0); // Runtime TypeError before the method body runs.
```

The same problem can occur even when a branch would not use the argument. The
runtime check belongs to method dispatch, not to the branch inside the method.

## Positive and negative positions

Use these signs when auditing a signature:

- A return position is positive (`+`).
- A method or function parameter position is negative (`-`).
- Entering a covariant type, such as `Either<L, R>`, preserves the sign.
- Entering a function parameter flips the sign.
- Entering a function return type preserves the sign.

Multiply the signs along the path to each occurrence of `L` or `R`:

- `+ x + = +`
- `+ x - = -`
- `- x + = -`
- `- x - = +`

A type parameter that occurs only positively is compatible with covariance. A
negative occurrence, or a mixture of positive and negative occurrences, makes
an instance-member boundary unsafe for widened receivers and requires a
different design.

## Why `map` is safe

Consider:

```dart
Either<L, C> map<C>(C Function(R value) transform);
```

As a standalone function type, `C Function(R)` is contravariant in `R` and
covariant in `C`: its parameter is `in R` and its result is `out C`.

However, `transform` is itself an input parameter of `map`. The path to `R`
therefore crosses two input positions:

```text
transform is a method parameter: -
R is a function parameter:      -
                                 - x - = +
```

From the perspective of `Either`, the value flows out of `Either` and into the
callback. A callback that accepts every `num` can safely accept the `int` held
by a runtime `Right<Never, int>`:

```dart
final Either<String, num> either = const Right<Never, int>(1);
either.map((num value) => value.toString());
```

The same reasoning makes callback consumers such as `fold`, `onLeft`,
`onRight`, and `isRightAnd` covariance-safe.

## Why callback producers are different

Consider a lazy fallback:

```dart
R getOrElse(R Function() defaultValue);
```

The callback produces `R`, so the path has only one sign flip:

```text
defaultValue is a method parameter: -
R is the callback return type:      +
                                    - x + = -
```

The caller is supplying an `R` back to the receiver. A runtime
`Right<Never, int>` cannot safely accept a callback that may return any `num`,
such as a `double`, even if the `Right` branch would never invoke that callback.

## Mixed example: `flatMap`

Consider:

```dart
Either<L, C> flatMap<C>(Either<L, C> Function(R value) transform);
```

`R` is positive overall:

```text
transform is a method parameter: -
R is a function parameter:      -
                                 - x - = +
```

`L` in the callback result is negative overall:

```text
transform is a method parameter:   -
callback return type:               +
Either is covariant in L:           +
                                    - x + x + = -
```

The callback consumes `R`, which is safe, but it produces an `Either` carrying
`L` back to the receiver, which is not safe across a widened virtual boundary.
An operation can therefore be safe for one class type parameter and unsafe for
the other.

## Signature audit table

| Signature shape | Position of class type parameter | Instance-member result |
|---|---|---|
| `R? getOrNull()` | `R: +` | Safe |
| `C fold(C Function(L), C Function(R))` | `L/R: - x - = +` | Safe |
| `C map(C Function(R))` | `R: - x - = +` | Safe |
| `void onRight(void Function(R))` | `R: - x - = +` | Safe |
| `bool isRightAnd(bool Function(R))` | `R: - x - = +` | Safe |
| `R getOrDefault(R)` | `R: -` and `R: +` | Unsafe |
| `R getOrElse(R Function())` | input `R: - x + = -` | Unsafe |
| `combine(Either<L, R> other, ...)` | `L/R: - x + = -` in `other` | Unsafe |
| `flatMap(Either<L, C> Function(R))` | `R: +`, callback-result `L: -` | Unsafe for `L` |
| `handleErrorWith(Either<C, R> Function(L))` | `L: +`, callback-result `R: -` | Unsafe for `R` |

"Unsafe" here means unsafe as a virtual instance-member boundary for a
covariantly widened receiver. It does not mean the operation itself is invalid.

## `EitherEffect` must be contravariant

Binding consumes an `Either<L, R>`, so a nominal `EitherEffect<L>` class with
an instance `bind` method is unsafe when Dart widens its covariant `L`. The
binding capability instead uses a named record containing a generic function:

```dart
typedef EitherEffect<L> = ({
  _EitherEffectBrand brand,
  R Function<R>(Either<L, R> either) bind,
});
```

The private-typed `brand` field does not mention `L`, so it does not affect the
variance calculation. It prevents a consumer that has not received a
package-issued marker from independently constructing the structural record.
The binding callback remains the source of scope isolation and revocation;
the brand itself is not a runtime authenticity check.

The path to `L` has one sign flip:

```text
record field type:                 +
bind function parameter:           -
Either is covariant in L:          +
                                    + x - x + = -
```

`EitherEffect` is therefore contravariant in `L`. An effect that accepts every
`num` left value can safely be narrowed to one used only with `int`; the
opposite assignment is rejected:

```dart
void demonstrate(
  EitherEffect<num> numbers,
  EitherEffect<int> onlyIntegers,
) {
  final EitherEffect<int> integers = numbers; // Safe.
  final EitherEffect<num> unsafe = onlyIntegers; // Compile-time error.
}
```

The named `bind` field also makes `effect.bind(...)` discoverable without
moving the consuming operation back onto a covariant nominal receiver. The
implementation matches `Left` and `Right` directly instead of passing the
consumed `Either` through another virtual method boundary. See
[ADR 0001](adr/0001-scope-bound-contravariant-either-effect.md).

## Project design rule

Before adding or changing a public instance member on `Either<L, R>`, audit
every occurrence of `L` and `R` through nested generic and function types.

1. Keep the operation as an instance member only when `L` and `R` occur solely
   in positive positions.
2. If either type parameter occurs negatively or invariantly, implement the
   operation as a generic extension or a top-level generic function.
3. In that extension or function, use direct sealed-class pattern matching or
   delegate only to a primitive that has already been proven covariance-safe.
4. Do not assume that an extension is automatically safe. An extension that
   calls an unsafe virtual instance method re-enters the same runtime boundary.

A safe extension shape is:

```dart
extension GetOrDefaultEitherExtension<L, R> on Either<L, R> {
  R getOrDefault(R defaultValue) => switch (this) {
        Left() => defaultValue,
        Right(value: final value) => value,
      };
}
```

Extension resolution uses the receiver's static type arguments. The direct
`switch` reads the sealed value without dispatching an input through the
runtime subtype's narrower generic signature.

For the same reason, prefer direct pattern matching for `flatten` rather than
delegating to a method whose signature has not passed the variance audit:

```dart
extension FlattenEitherExtension<L, R> on Either<L, Either<L, R>> {
  Either<L, R> flatten() => switch (this) {
        Left(value: final value) => Either.left(value),
        Right(value: final value) => value,
      };
}
```

## Current PR audit

The branch review that introduced this document found and fixed three targets:

- `getOrDefault` now uses `GetOrDefaultEitherExtension`, so its `R` input does
  not cross an instance-method boundary.
- `combine` now uses `CombineEitherExtension`, so the other `Either<L, R>` and
  combiner results are checked against the call site's static type arguments.
- `flatten` remains an extension but now uses direct sealed-class pattern
  matching instead of delegating to `flatMap`.
- `EitherEffect` is a branded, contravariant record capability, so unsafe
  widening and independent construction are rejected before a binding block
  can execute.

The other APIs added in this PR were audited as covariance-safe instance
members or extensions: `onLeft`, `onRight`, `getOrNull`, `leftOrNull`,
`isRightAnd`, and `merge`.

The audited implementation primitive and canonical operations carry the
internal `@covarianceSafe` marker:

- Proven from their signatures and audited implementations: `_foldInternal`,
  `fold`, `map`, `onLeft`, `onRight`, `getOrNull`, `leftOrNull`, and
  `isRightAnd`.
- Covered by widened covariance regression tests: `getOrDefault`, `combine`,
  `flatten`, and `merge`.

The marker records a completed audit; it does not make an operation safe and
is not enforced by the Dart type system. Apply it only when either:

1. Every `L` and `R` occurrence is positive and the implementation uses direct
   pattern matching or only already-proven covariance-safe primitives.
2. The signature contains negative or invariant occurrences, so the operation
   is implemented as a generic extension or top-level function using direct
   pattern matching or a proven-safe primitive, with widened regression
   coverage for the relevant paths.

Deprecated naming aliases introduced in this PR intentionally remain unmarked.
Their compatibility tests verify delegation to the marked canonical operation.

This marker set is intentionally not exhaustive. Other pre-existing APIs must
still be audited separately before they are reused as implementation primitives
or changed in a future release.

## Required regression tests

Normal `Either<L, R>` tests are insufficient because they often construct the
runtime object with exactly the same type arguments as the static variable.
Every operation affected by variance must also be tested with widened values:

```dart
final Either<String, int> widenedLeft =
    const Left<String, Never>('error');
final Either<String, int> widenedRight =
    const Right<Never, int>(1);
final Either<String, num> widenedRightValue =
    const Right<Never, int>(1);
```

For nested operations, include a widened nested value:

```dart
final Either<String, Either<String, int>> widenedNested =
    const Right<Never, Either<Never, int>>(
  Right<Never, int>(1),
);
```

Tests must cover:

- `Left<L, Never>` widened to `Either<L, R>`.
- `Right<Never, R>` widened to `Either<L, R>`.
- A right value subtype widened to a supertype, such as `int` to `num`.
- Both receiver directions for binary operations.
- Nested widening for operations such as `flatten`.
- Callback invocation counts, including callbacks that must not run.
- Successful execution without `TypeError`; do not hide the issue with casts.
- Safe contravariant narrowing of `EitherEffect`, plus a compile-fail fixture
  that requires unsafe widening to report `INVALID_ASSIGNMENT`.
- A consumer compile-fail fixture showing that a record with a compatible
  generic `bind` function but no package-issued brand cannot be assigned to
  `EitherEffect`.

## Review checklist

- Trace every `L` and `R` occurrence through method parameters, function
  parameters, function returns, and covariant containers.
- Treat every negative or mixed occurrence as a virtual-boundary risk.
- Prefer a generic extension or top-level function for risky signatures.
- Use direct `switch` pattern matching or a proven covariance-safe primitive.
- Add widened `Never` and subtype regression tests.
- Apply `@covarianceSafe` only after recording one of the accepted forms of
  evidence above; never treat the marker itself as evidence.
- Verify with `dart analyze` and `dart test`.
