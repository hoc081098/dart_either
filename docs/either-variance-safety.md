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
Either<L, R2> map<R2>(R2 Function(R value) transform);
```

As a standalone function type, `R2 Function(R)` is contravariant in `R` and
covariant in `R2`: its parameter is `in R` and its result is `out R2`.

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
`onRight`, `isLeftAnd`, and `isRightAnd` covariance-safe.

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
Either<L, R2> flatMap<R2>(Either<L, R2> Function(R value) transform);
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

## Complete `Either` instance-member audit

The following table covers every public instance member declared directly on
`Either<L, R>`. `Left.value` and `Right.value` expose their type parameter only
as output, so those subtype fields are also safe. Object overrides on `Left`
and `Right` do not consume `L` or `R` in their signatures.

| Member | Position of class type parameter | Instance-member result |
|---|---|---|
| `isLeft`, `isRight` | No `L` or `R` occurrence | Safe |
| `fold(T Function(L), T Function(R))` | `L/R: - x - = +` | Safe |
| `foldLeft(T, T Function(T, R))` | `R: - x - = +` | Safe |
| `swap()` | `L/R: +` in the returned `Either<R, L>` | Safe |
| `onLeft(void Function(L))` | callback `L: - x - = +`; returned `L/R: +` | Safe |
| `onRight(void Function(R))` | callback `R: - x - = +`; returned `L/R: +` | Safe |
| `map(R2 Function(R))` | callback `R: - x - = +`; returned `L: +` | Safe |
| `mapLeft(L2 Function(L))` | callback `L: - x - = +`; returned `R: +` | Safe |
| `bimap(L2 Function(L), R2 Function(R))` | callback `L/R: - x - = +` | Safe |
| `isLeftAnd(bool Function(L))` | `L: - x - = +` | Safe |
| `isRightAnd(bool Function(R))` | `R: - x - = +` | Safe |
| `all(bool Function(R))` | `R: - x - = +` | Safe |
| `getOrNull()` | returned `R: +` | Safe |
| `leftOrNull()` | returned `L: +` | Safe |
| `findOrNull(bool Function(R))` | callback `R: +`; returned `R: +` | Safe |
| `when(T Function(Left<L, R>), T Function(Right<L, R>))` | `L/R: - x - x + = +` | Safe |
| `redeem(R2 Function(L), R2 Function(R))` | callback `L/R: - x - = +`; returned `L: +` | Safe |
| `redeemWith(Either<L2, R2> Function(L), Either<L2, R2> Function(R))` | callback input `L/R: - x - = +`; callback results use only fresh `L2/R2` | Safe |

Deprecated `tapLeft`, `tap`, `exists`, and `orNull` have the same safe shape as
their canonical targets and only forward to those targets. They remain
unmarked so the marker identifies canonical operations rather than
compatibility names.

The generic-extension operations `flatMap`, `getOrElse`, `getOrHandle`,
`getOrDefault`, `handleError`, `handleErrorWith`, and `combine` would be unsafe
with their current signatures as virtual instance members because their direct
callback-produced or direct inputs are negative. They are safe in this package
because extension resolution uses the receiver's static type arguments and
their implementations pattern-match directly. `flatten` and `merge` are
specialized extensions with widened regression coverage.

"Unsafe" here means unsafe as a virtual instance-member boundary for a
covariantly widened receiver. It does not mean the operation itself is invalid.

## `EitherEffect` must be contravariant

Binding consumes an `Either<L, R>`, so a nominal `EitherEffect<L>` class with
an instance `bind` method is unsafe when Dart widens its covariant `L`. The
binding capability instead aliases a library-private final scope whose type
argument is a phantom function type:

```dart
typedef EitherEffect<L> = _BindingScope<Never Function(L)>;
```

`_BindingScope<T>` is covariant in `T`, while a function is contravariant in
its parameter. Composing those two positions makes the alias contravariant in
`L`:

```text
alias target:                       +
_BindingScope type argument:        +
function parameter:                 -
                                      + x + x - = -
```

An effect that accepts every `num` left value can therefore be narrowed to one
used only with `int`; the opposite assignment is rejected:

```dart
void demonstrate(
  EitherEffect<num> numbers,
  EitherEffect<int> onlyIntegers,
) {
  final EitherEffect<int> integers = numbers; // Safe.
  final EitherEffect<num> unsafe = onlyIntegers; // Compile-time error.
}
```

The phantom type has no runtime function value. `_BindingScope` itself owns the
scope token and lifecycle state, and its named private constructor prevents the
public typedef from forwarding an unnamed constructor. Keeping the carrier
final and library-private also prevents external implementations. Copying an
issued effect only aliases the same scope, so it cannot replace binding
behavior or escape revocation.

`BindEitherEffectExtension.bind` is declared in the same Dart library as the
private scope. It ties the call-site `L` to `Either<L, R>` and delegates to a
private generic operation that matches `Left` and `Right` directly. This keeps
`effect.bind(...)` discoverable without introducing a consuming method on a
covariant public class. See
[ADR 0001](adr/0001-scope-bound-contravariant-either-effect.md).

`RaiseEitherEffectExtension.raise` follows the same extension-to-private-scope
pattern. Its regression coverage calls `raise` through a safely narrowed
`EitherEffect` so the new call boundary is checked independently of `bind`.

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

## Completed audit evidence

The completed audit and subsequent relocation fixed these targets:

- `getOrDefault` now uses `GetOrDefaultEitherExtension`, so its `R` input does
  not cross an instance-method boundary.
- `combine` now uses `CombineEitherExtension`, so the other `Either<L, R>` and
  combiner results are checked against the call site's static type arguments.
- `flatten` remains an extension but now uses direct sealed-class pattern
  matching instead of delegating to `flatMap`.
- `flatMap`, deprecated `getOrElse`, `getOrHandle`, `handleError`, and
  `handleErrorWith` moved from unsafe virtual members to generic extensions in
  `2.4.0`. Their implementations pattern-match directly and their widened
  regression tests cover both `Left` and `Right` paths.
- `EitherEffect` uses a private final scope with a contravariant phantom marker,
  so unsafe widening, external construction, and replacement binding behavior
  are rejected before a binding block can execute.

The audited implementation primitive and every canonical safe operation
declared directly on `Either` carry the internal `@covarianceSafe` marker:

- `_foldInternal`, `fold`, `foldLeft`, `swap`, `onLeft`, `onRight`, `map`,
  `mapLeft`, `bimap`, `isLeftAnd`, `isRightAnd`, `all`, `getOrNull`,
  `leftOrNull`, `findOrNull`, `when`, `redeem`, and `redeemWith`;
- generic or specialized extensions covered by widened regression tests:
  `flatMap`, `getOrElse`, `getOrHandle`, `getOrDefault`, `handleError`,
  `handleErrorWith`, `combine`, `flatten`, `merge`, `getOrThrow`, and
  `toFuture`.

The `isLeft` and `isRight` getters contain no occurrence of `L` or `R` in their
signatures. They are covered by widened inspection tests but do not need an
operation marker. No public instance member identified by the completed audit
remains variance-unsafe after the `2.4.0` relocation.

The marker records a completed audit; it does not make an operation safe and
is not enforced by the Dart type system. Apply it only when either:

1. Every `L` and `R` occurrence is positive and the implementation uses direct
   pattern matching or only already-proven covariance-safe primitives.
2. The signature contains negative or invariant occurrences, so the operation
   is implemented as a generic extension or top-level function using direct
   pattern matching or a proven-safe primitive, with widened regression
   coverage for the relevant paths.

Deprecated forwarding naming aliases intentionally remain unmarked. Their
compatibility tests verify delegation to the marked canonical operation. The
deprecated `getOrElse` is different: ADR 0002 relocates the operation itself,
so its generic extension is directly implemented, covered by widened tests,
and marked `@covarianceSafe`.

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
- A consumer compile-fail fixture showing that `EitherEffect<L>()` exposes no
  unnamed constructor and reports `NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT`.

## Review checklist

- Trace every `L` and `R` occurrence through method parameters, function
  parameters, function returns, and covariant containers.
- Treat every negative or mixed occurrence as a virtual-boundary risk.
- Prefer a generic extension or top-level function for risky signatures.
- Use direct `switch` pattern matching or a proven covariance-safe primitive.
- Add widened `Never` and subtype regression tests.
- Keep the `EitherEffect` carrier final and library-private, and keep its
  constructor named and private so the public typedef cannot forward it.
- Apply `@covarianceSafe` only after recording one of the accepted forms of
  evidence above; never treat the marker itself as evidence.
- Verify with `dart analyze` and `dart test`.
