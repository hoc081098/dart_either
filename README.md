# dart_either

> **Author:** [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Dart CI](https://github.com/hoc081098/dart_either/workflows/Dart%20CI/badge.svg)](https://github.com/hoc081098/dart_either/actions)
[![pub version](https://img.shields.io/pub/v/dart_either)](https://pub.dev/packages/dart_either)
[![pub prerelease](https://img.shields.io/pub/v/dart_either?include_prereleases)](https://pub.dev/packages/dart_either)
[![codecov](https://codecov.io/gh/hoc081098/dart_either/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/dart_either)
[![License: MIT](https://img.shields.io/github/license/hoc081098/dart_either?color=4EB1BA)](https://opensource.org/licenses/MIT)
[![Style: lints](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)
[![Hits](https://hits.sh/github.com/hoc081098/dart_either.svg)](https://hits.sh/github.com/hoc081098/dart_either/)

**Either monad for Dart & Flutter** — a type-safe, lightweight library for error handling and railway-oriented programming.

- ✅ **Monad comprehensions** — both `sync` (`Either.binding`) and `async` (`Either.futureBinding`) versions.
- ✅ **Async `map` / `flatMap`** — hides the boilerplate of working with `Future<Either<L, R>>`.
- ✅ **Type-safe** — an explicit, compiler-friendly alternative to nullable values and thrown exceptions.

> **Credits:** Ported and adapted from [Λrrow-kt](https://github.com/arrow-kt/arrow).

---

## Support the project

If you find this library useful, consider buying me a coffee ☕

<a href="https://www.buymeacoffee.com/hoc081098" target="_blank" rel="noopener noreferrer">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height="64">
</a>

---

## Why `dart_either`?

### Difference from [dartz](https://pub.dev/packages/dartz) and [fpdart](https://pub.dev/packages/fpdart)

Many projects import entire FP libraries (dartz, fpdart, …) but only use `Either`. This library extracts and adapts just the `Either` class from [Λrrow-kt](https://github.com/arrow-kt/arrow), keeping things focused and lightweight.

| Feature              | dart_either                                                                                                                   |
|----------------------|-------------------------------------------------------------------------------------------------------------------------------|
| Inspired by          | [Λrrow-kt](https://github.com/arrow-kt/arrow), [Scala Cats](https://typelevel.org/cats/typeclasses.html#type-classes-in-cats) |
| Documentation        | **Fully documented** — every method/function has doc comments and examples                                                    |
| Test coverage        | **Fully tested**                                                                                                              |
| Completeness         | **Most complete** `Either` implementation available for Dart/Flutter                                                          |
| Monad comprehensions | ✅ Both `sync` and `async`                                                                                                     |
| Async map / flatMap  | ✅ `thenMapEither`, `thenFlatMapEither`                                                                                        |
| Bundle size          | Very **lightweight** and **simple** (compare to dartz)                                                                        |

---

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dart_either: ^2.2.0
```

Then run:

```bash
dart pub get
```

---

## Documentation & Examples

| Resource             | Link                                                                                  |
|----------------------|---------------------------------------------------------------------------------------|
| 📖 API Documentation | https://pub.dev/documentation/dart_either/latest/dart_either/ |
| 💡 Examples          | https://github.com/hoc081098/dart_either/tree/master/example/lib                      |
| 🐦 Flutter Example   | https://github.com/hoc081098/node-auth-flutter-BLoC-pattern-RxDart                    |

---

## Either monad

`Either<L, R>` represents one of two possible values:

- **`Right(R)`** — the "desired" / success value (right-biased).
- **`Left(L)`** — the "undesired" / error value.

Related implementations in other languages:
- [Elm Result](https://package.elm-lang.org/packages/elm-lang/core/5.1.1/Result)
- [Haskell Data.Either](https://hackage.haskell.org/package/base-4.10.0.0/docs/Data-Either.html)
- [Rust Result](https://doc.rust-lang.org/std/result/enum.Result.html)

<details>
  <summary>Why Either? (click to expand)</summary>

In day-to-day programming, it is fairly common to find ourselves writing functions that can fail.
For instance, querying a service may result in a connection issue, or some unexpected `JSON` response.

To communicate these errors, it has become common practice to throw exceptions; however,
exceptions are not tracked in any way, shape, or form by the compiler. To see what
kind of exceptions (if any) a function may throw, we have to dig through the source code.
Then, to handle these exceptions, we have to make sure we catch them at the call site. This
all becomes even more unwieldy when we try to compose exception-throwing procedures.

```dart
// What exceptions can this throw? You have to dig through the source to find out.
double throwsSomeStuff(int i) => throw UnimplementedError();

// Same here — no way to know from the type signature alone.
String throwsOtherThings(double d) => throw UnimplementedError();

// And here too.
List<int> moreThrowing(String s) => throw UnimplementedError();

// Any of the three above can throw — good luck tracking which one failed!
List<int> magic(int i) => moreThrowing( throwsOtherThings( throwsSomeStuff(i) ) );
```

Assume we happily throw exceptions in our code. Looking at the types of the functions above,
any could throw a number of exceptions — we do not know. When we compose, exceptions from any
of the constituent functions can be thrown. Moreover, they may throw the same kind of exception
(e.g., `ArgumentError`) and, thus, it gets tricky tracking exactly where an exception came from.

**How then do we communicate an error? By making it explicit in the data type we return.**

`Either` is used to short-circuit a computation upon the first error.
By convention, the right side of an `Either` is used to hold successful values.

Because `Either` is right-biased, it is possible to define a `Monad` instance for it.
Since we only ever want the computation to continue in the case of `Right` (as captured by
the right-bias nature), we fix the left type parameter and leave the right one free.
So, the `map` and `flatMap` methods are right-biased.

**Example:**

```dart
// 1) Creation
// Create an instance of [Right]
final Either<String, int> right = Either.right(10); // Either.Right(10)

// Create an instance of [Left]
final Either<String, int> left = Either.left('none'); // Either.Left(none)

// Map the right value to a [String]
final Either<String, String> mapRight = right.map((a) => 'String: $a'); // Either.Right(String: 10)

// Map the left value to an [int]
final Either<int, int> mapLeft = right.mapLeft((a) => a.length); // Either.Right(10)

// Return [Left] if the action throws an error, otherwise return [Right]
final Either<String, int> tryCatchResult = Either.tryCatch(
  action: () => int.parse('invalid'),
  errorMapper: (e, s) => 'Error: $e',
);
// Either.Left(Error: FormatException: Invalid radix-10 number (at character 1)
// invalid
// ^
// )

// 2) Operations
// Extract the value from [Either]
final int value1 = right.getOrDefault(-1); // 10
final int value2 = right.getOrHandle((l) => -1); // 10

// Chain computations
final Either<String, int> flatMap = right.flatMap((a) => Either.right(a + 10)); // Either.Right(20)
final Either<String, int> combined = right.combine(
  Either<String, int>.right(5),
  combineLeft: (a, b) => '$a,$b',
  combineRight: (a, b) => a + b,
); // Either.Right(15)
final Either<String, int> flattened = Either<String, Either<String, int>>.right(
  Either<String, int>.right(10),
).flatten(); // Either.Right(10)
final int merged = Either<int, int>.right(10).merge(); // 10

// 3) Pattern matching
// Pattern matching
right.fold(
  ifLeft: (l) => print('Left value: $l'),
  ifRight: (r) => print('Right value: $r'),
); // Right value: 10

right.when(
  ifLeft: (l) => print('Left: $l'),
  ifRight: (r) => print('Right: $r'),
); // Prints Right: Either.Right(10)

// Or use Dart 3.0 switch expression syntax 🤘
print(
  switch (right) {
    Left() => 'Left: $right',
    Right() => 'Right: $right',
  },
); // Prints Right: Either.Right(10)

// Convert to nullable value
final int? nullableValue = right.getOrNull(); // 10
final String? leftValue = left.leftOrNull(); // 'none'
print(leftValue); // 'none'
print(nullableValue); // 10
```

</details>

---

## API Reference

> Full API docs: https://pub.dev/documentation/dart_either/latest/dart_either/

### 1. Creating `Either` values

| Constructor                                                                                                       | Description                 |
|-------------------------------------------------------------------------------------------------------------------|-----------------------------|
| [`Either.left`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.left.html)             | Creates a `Left` value      |
| [`Either.right`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.right.html)           | Creates a `Right` value     |
| [`Either.fromNullable`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/fromNullable.html)    | Converts a nullable value   |
| [`Left`](https://pub.dev/documentation/dart_either/latest/dart_either/Left/Left.html)                             | Direct `Left` constructor   |
| [`Right`](https://pub.dev/documentation/dart_either/latest/dart_either/Right/Right.html)                          | Direct `Right` constructor  |
| [`T.left`](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherObjectExtension/left.html)        | Wraps any value as `Left`   |
| [`T.right`](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherObjectExtension/right.html)      | Wraps any value as `Right`  |

```dart
// 1) Create Left/Right
final Either<Object, String> left = Either.left('Left value');
// or: Left<Object, String>('Left value')

final Either<Object, int> right = Either.right(1);
// or: Right<Object, int>(1)

// 2) Convert a nullable value
Either.fromNullable<int>(null); // Either.Left(null)
Either.fromNullable<int>(1);    // Either.Right(1)

// 3) Receiver-style constructors
final Either<int, String> receiverLeft = 1.left<String>(); // Either.Left(1)
final Either<String, int> receiverRight = 1.right<String>(); // Either.Right(1)
```

---

### 2. Error capture

| API                                                                                                                        | Description                                  |
|----------------------------------------------------------------------------------------------------------------------------|----------------------------------------------|
| [`Either.tryCatch`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.tryCatch.html)              | Captures errors thrown by a synchronous action |
| [`Either.tryCatchAsync`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/tryCatchAsync.html)            | Captures sync and async errors from an action |
| [`Future.toEitherFuture`](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherFutureExtension/toEitherFuture.html) | Converts an existing future's outcome    |
| [`Stream.toEitherStream`](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherStreamExtension/toEitherStream.html) | Converts an existing stream's events     |
| [`Either.registerFatalError`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/registerFatalError.html) | Excludes an error type from capture           |

Use `tryCatch` for synchronous actions and `tryCatchAsync` when invoking an
asynchronous action may fail either before or after it returns a future:

```dart
final Either<String, int> parsed = Either.tryCatch(
  action: () => int.parse('invalid'),
  errorMapper: (error, stackTrace) => 'Error: $error',
); // Either.Left(Error: FormatException: ...)

final Either<String, int> loaded = await Either.tryCatchAsync(
  action: () async => int.parse('42'),
  errorMapper: (error, stackTrace) => 'Error: $error',
); // Either.Right(42)
```

Use the receiver extensions when the `Future` or `Stream` has already been
created:

```dart
String mapError(Object error, StackTrace stackTrace) => 'Error: $error';

final Either<String, int> futureRight = await Future<int>.value(1).toEitherFuture(mapError);
final Either<String, int> futureLeft = await Future<int>.error(Exception('boom')).toEitherFuture(mapError);

print(futureRight); // Either.Right(1)
print(futureLeft);  // Either.Left(Error: Exception: boom)

final Stream<Either<String, int>> valueStream = Stream<int>.fromIterable([1, 2]).toEitherStream(mapError);
final Stream<Either<String, int>> errorStream = Stream<int>.error(Exception('boom')).toEitherStream(mapError);

print(await valueStream.toList()); // [Either.Right(1), Either.Right(2)]
print(await errorStream.toList()); // [Either.Left(Error: Exception: boom)]
```

Register application-specific errors that must not be converted to `Left`:

```dart
class CancellationException implements Exception {}

void configureErrorCapture() {
  Either.registerFatalError<CancellationException>();
}
```

`registerFatalError<T>()` keeps a separate registry in each Dart isolate.
Registering a type in one isolate does not affect other isolates, so each
spawned isolate must register the types it needs. Registrations are additive,
and registering the same type more than once has no additional effect.

The policy applies to `tryCatch`, `tryCatchAsync`, `Future.toEitherFuture`, and
`Stream.toEitherStream`. An error matching a registered type, including any
subtype of it, remains an error instead of being converted to `Left`.

Both `Right` and `Left` are ordinary values in the returned `Either`. A matching
fatal error stays in Dart's error channel instead: `tryCatch` rethrows it, the
Future-based APIs complete with it as an error, and `toEitherStream` forwards it
as a stream error event. Internal binding-control signals are excluded from
capture automatically.

#### Migrating from deprecated error-capture APIs

The old names remain available in `2.x` so existing code keeps working:

- `Either.catchError` is deprecated in favor of `Either.tryCatch`.
- `Either.catchFutureError` is deprecated in favor of `Either.tryCatchAsync`.
- `Either.catchStreamError` is deprecated in favor of
  `Stream.toEitherStream`.

---

### 3. Collection operations

| API                                                                                                                 | Description                              |
|---------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| [`Either.sequence`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/sequence.html)             | Sequences multiple `Either` values       |
| [`Either.traverse`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/traverse.html)             | Maps values and sequences the results    |
| [`Either.parSequenceN`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/parSequenceN.html)     | Sequences async actions with concurrency control |
| [`Either.parTraverseN`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/parTraverseN.html)     | Maps and runs async actions with concurrency control |

```dart
import 'package:built_collection/built_collection.dart';

final Either<String, BuiltList<int>> sequenced = Either.sequence([Either.right(1), Either.right(2)]);

final Either<String, BuiltList<int>> traversed = Either.traverse(
  ['1', 'invalid'],
  (text) => Either.tryCatch(
    action: () => int.parse(text),
    errorMapper: (error, stackTrace) => 'Invalid integer: $text',
  ),
);

Future<Either<String, int>> fetchNumber(int value) async => Either.right(value);

final Either<String, BuiltList<int>> parallelSequence = await Either.parSequenceN(
  functions: [
    () => fetchNumber(1),
    () => fetchNumber(2),
  ],
  maxConcurrent: 2,
);

final Either<String, BuiltList<int>> parallelTraverse = await Either.parTraverseN(
  values: [1, 2],
  mapper: (value) => () => fetchNumber(value),
  maxConcurrent: 2,
);
```

---

### 4. Operations on `Either`

#### Inspecting and folding

| Method                                                                                                                 | Description                                   |
|------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------|
| [`isLeft`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isLeft.html)                            | Returns `true` if this is a `Left`            |
| [`isRight`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isRight.html)                          | Returns `true` if this is a `Right`           |
| [`isLeftAnd`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isLeftAnd.html)                      | Tests the `Left` value with a predicate       |
| [`isRightAnd`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isRightAnd.html)                    | Tests the `Right` value with a predicate      |
| [`all`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/all.html)                                  | Returns `true` for `Left` or a matching `Right` |
| [`findOrNull`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/findOrNull.html)                    | Finds a matching `Right` value                |
| [`fold`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/fold.html)                                | Applies one of two functions based on variant |
| [`foldLeft`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/foldLeft.html)                        | Left fold with an initial value               |
| [`when`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/when.html)                                | Pattern-matches and returns the matched value |

#### Transforming and composing

| Method                                                                                                         | Description                                  |
|----------------------------------------------------------------------------------------------------------------|----------------------------------------------|
| [`map`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/map.html)                                  | Transforms the `Right` value                  |
| [`mapLeft`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/mapLeft.html)                          | Transforms the `Left` value                   |
| [`flatMap`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/flatMap.html)                          | Chains computations                           |
| [`bimap`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/bimap.html)                              | Transforms both sides                         |
| [`swap`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/swap.html)                                | Swaps `Left` and `Right`                      |
| [`combine`](https://pub.dev/documentation/dart_either/latest/dart_either/CombineEitherExtension/combine.html)         | Combines two `Either` values                  |
| [`flatten`](https://pub.dev/documentation/dart_either/latest/dart_either/FlattenEitherExtension/flatten.html)          | Flattens nested `Either`                      |
| [`merge`](https://pub.dev/documentation/dart_either/latest/dart_either/MergeEitherExtension/merge.html)                | Extracts a value when both sides have the same type |

#### Recovering and extracting

| Method                                                                                                                 | Description                                      |
|------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| [`getOrDefault`](https://pub.dev/documentation/dart_either/latest/dart_either/GetOrDefaultEitherExtension/getOrDefault.html) | Extracts `Right` or falls back to an eager default value |
| [`getOrNull`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/getOrNull.html)                      | Extracts `Right` or returns `null`            |
| [`leftOrNull`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/leftOrNull.html)                    | Extracts `Left` or returns `null`             |
| [`getOrHandle`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/getOrHandle.html)                  | Extracts `Right` or maps `Left` to a value    |
| [`handleErrorWith`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/handleErrorWith.html)          | Recovers from `Left` with a new `Either`      |
| [`handleError`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/handleError.html)                  | Recovers from `Left` with a new `Right` value |
| [`redeem`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/redeem.html)                            | Maps both sides to the same type              |
| [`redeemWith`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/redeemWith.html)                    | Maps both sides to a new `Either`             |
| [`getOrThrow`](https://pub.dev/documentation/dart_either/latest/dart_either/GetOrThrowEitherExtension/getOrThrow.html) | Extracts `Right` or throws the `Left` value   |

#### Side effects and conversion

| Method                                                                                                           | Description           |
|------------------------------------------------------------------------------------------------------------------|-----------------------|
| [`onLeft`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/onLeft.html)                      | Side effect on `Left` |
| [`onRight`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/onRight.html)                    | Side effect on `Right` |
| [`toFuture`](https://pub.dev/documentation/dart_either/latest/dart_either/AsFutureEitherExtension/toFuture.html) | Converts to a `Future` |

```dart
final Either<String, int> ok = Either.right(10);
final Either<String, int> err = Either.left('boom');

// Predicates
ok.isRightAnd((v) => v > 0); // true
err.isLeftAnd((v) => v == 'boom'); // true
err.all((_) => false); // true

// Side effects
ok.onRight(print); // prints 10
err.onLeft(print); // prints boom

// Transformations and composition
ok.map((v) => v + 1); // Right(11)
ok.combine(
  Either<String, int>.right(2),
  combineLeft: (a, b) => '$a,$b',
  combineRight: (a, b) => a + b,
); // Right(12)
Either<String, Either<String, int>>.right(ok).flatten(); // Right(10)

// Recovery
err.handleError((l) => l.length); // Right(4)
err.handleErrorWith((l) => Either<String, int>.right(l.length)); // Right(4)

// Extractions
ok.getOrDefault(0); // 10
err.getOrHandle((l) => l.length); // 4
ok.getOrNull(); // 10
err.leftOrNull(); // 'boom'
Either<int, int>.right(10).merge(); // 10

// Pattern matching
ok.fold(
  ifLeft: (l) => 'Left: $l',
  ifRight: (r) => 'Right: $r',
); // Right: 10
```

#### Migrating from deprecated operation names

- `tapLeft` is deprecated in favor of `onLeft`.
- `tap` is deprecated in favor of `onRight`.
- `orNull` is deprecated in favor of `getOrNull`.
- `exists` is deprecated in favor of `isRightAnd`.
- `getOrElse` is deprecated. Use `getOrDefault(value)` for an eager fallback,
  or `getOrHandle((left) => value)` for a lazy, left-aware fallback.

---

### 5. Monad comprehensions

Use `Either.binding` (sync) or `Either.futureBinding` (async) for do-notation
style sequential computations that short-circuit on the first `Left`.

Their callback receives an `EitherEffect<L>`: a package-issued, opaque,
scope-bound binding capability. Use it as `effect.bind(either)`,
`either.bind(effect)`, `eitherFuture.bind(effect)`, or `effect.raise(value)`.
Its construction and binding behavior are library-owned; assigning it to
another variable only aliases the same scope. Each `Either.binding` or
`Either.futureBinding` invocation owns an isolated scope, ordinary exceptions
propagate unchanged, and the capability must not be stored or invoked after
that scope settles.

#### Running a binding scope

| API                                                                                                                                              | Description                        |
|--------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------|
| [`Either.binding`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.binding.html)                                      | Runs a synchronous binding scope   |
| [`Either.futureBinding`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/futureBinding.html)                                 | Runs an asynchronous binding scope |

#### Extracting bound values

These four forms have the same short-circuit semantics; choose the syntax that
best matches the value already in hand.

| API                                                                                                                                                 | Description                                 |
|-----------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------|
| [`EitherEffect.bind`](https://pub.dev/documentation/dart_either/latest/dart_either/BindEitherEffectExtension/bind.html)                             | Extracts an `Either` through the capability |
| [`Either.bind`](https://pub.dev/documentation/dart_either/latest/dart_either/BindEitherExtension/bind.html)                                         | Extracts itself through an `EitherEffect`   |
| [`EitherEffect.bindFuture`](https://pub.dev/documentation/dart_either/latest/dart_either/BindFutureEitherEffectExtension/bindFuture.html)           | Awaits and extracts a future `Either`       |
| [`Future<Either>.bind`](https://pub.dev/documentation/dart_either/latest/dart_either/BindEitherFutureExtension/bind.html)                           | Awaits and extracts itself                  |

#### Guarding and short-circuiting

| API                                                                                                                                                | Description                                         |
|----------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------|
| [`EitherEffect.ensure`](https://pub.dev/documentation/dart_either/latest/dart_either/EnsureEitherEffectExtension/ensure.html)                      | Requires a condition to be true                     |
| [`EitherEffect.ensureNotNull`](https://pub.dev/documentation/dart_either/latest/dart_either/EnsureNotNullEitherEffectExtension/ensureNotNull.html) | Extracts a non-null value or short-circuits         |
| [`EitherEffect.raise`](https://pub.dev/documentation/dart_either/latest/dart_either/RaiseEitherEffectExtension/raise.html)                         | Short-circuits directly with an available left value |

#### Synchronous binding

The following complete example combines the main `EitherEffect` operations:

- `ensureNotNull` extracts a required nullable value.
- `bind` unwraps a `Right` or propagates an existing `Left`.
- `ensure` checks a condition and short-circuits when it is false.
- `raise` short-circuits with an available left value without constructing a
  `Left` solely to bind it.

```dart
Either<String, int> parseQuantity(String input) {
  final int? quantity = int.tryParse(input);
  return quantity == null
      ? Either.left('Quantity must be an integer')
      : Either.right(quantity);
}

Either<String, int> calculateOrderTotal({
  required String? quantityInput,
  required int unitPrice,
  required int availableStock,
}) =>
    Either.binding((effect) {
      // 1) Require the nullable input.
      final String input = effect.ensureNotNull(
        quantityInput,
        () => 'Quantity is required',
      );

      // 2) Bind an Either, propagating its Left automatically.
      final int quantity = effect.bind(parseQuantity(input));

      // 3) Enforce a value-level invariant.
      effect.ensure(quantity > 0, () => 'Quantity must be positive');

      // 4) Raise a domain error without constructing a Left to bind.
      if (quantity > availableStock) {
        effect.raise('Only $availableStock items are in stock');
      }

      // 5) A normal return becomes Right(total).
      return quantity * unitPrice;
    });

final Either<String, int> successfulOrder = calculateOrderTotal(
  quantityInput: '3',
  unitPrice: 20,
  availableStock: 10,
); // Right(60)

final Either<String, int> invalidQuantity = calculateOrderTotal(
  quantityInput: 'three',
  unitPrice: 20,
  availableStock: 10,
); // Left('Quantity must be an integer')

final Either<String, int> insufficientStock = calculateOrderTotal(
  quantityInput: '12',
  unitPrice: 20,
  availableStock: 10,
); // Left('Only 10 items are in stock')
```

`raise` returns `Never`, so it also works naturally in expressions such as
`nullable ?? effect.raise('missing')`.

#### Asynchronous binding

`Either.futureBinding` opens an asynchronous binding scope. Inside that scope,
ordinary `await`, local variables, conditions, and `return` remain available:

- `either.bind(effect)` extracts a `Right` from an `Either` immediately.
- `await eitherFuture.bind(effect)` waits for a `Future<Either>` and extracts
  its `Right`.
- Both forms short-circuit the whole scope when they encounter a `Left`.
- An error from a `Future` is not converted to a `Left`; it propagates through
  the future's error channel. Use `Either.tryCatchAsync` when it should become a
  typed `Left` instead.

This is the direct-style alternative to the `Future<Either>` pipelines in the
next section. Use `Either.binding` for synchronous code and
`Either.futureBinding` as soon as the flow needs `await`. It is especially
useful when several `Either`-producing operations depend on values produced by
earlier steps: each value can be bound to a local variable, keeping the flow
flat instead of nesting callbacks.

The shortened example below uses the shared
[`AppError`, `toAppError`, and model decoders](https://github.com/hoc081098/dart_either/blob/master/example/lib/http_example/shared_model.dart)
from the [complete runnable binding example](https://github.com/hoc081098/dart_either/blob/master/example/lib/http_example/http_either_binding.dart).

```dart
Future<Either<AppError, dynamic>> httpGetAsEither(String uriString) =>
    Either.futureBinding((effect) async {
      // A synchronous Either can be bound without await.
      final Uri uri = Either.tryCatch(
        action: () => Uri.parse(uriString),
        errorMapper: toAppError('Parse $uriString'),
      ).bind(effect);

      // A Future<Either> is awaited and then bound. tryCatchAsync converts
      // non-fatal Future errors into AppError values on the Left.
      final http.Response response = await Either.tryCatchAsync(
        action: () => http.get(uri),
        errorMapper: toAppError('http.get($uri)'),
      ).bind(effect);

      final int statusCode = response.statusCode;
      final String body = response.body;

      // A failed guard also short-circuits this futureBinding scope.
      effect.ensure(
        statusCode >= 200 && statusCode < 300,
        () => AppError(
          HttpException(
            'statusCode=$statusCode, body=$body',
            uri: response.request?.url,
          ),
          StackTrace.current,
          'statusCode: $statusCode',
        ),
      );

      // Returning a plain value completes the scope with Right(value).
      return Either<AppError, dynamic>.tryCatch(
        action: () => jsonDecode(body),
        errorMapper: toAppError('jsonDecode: $body'),
      ).bind(effect);
    });

Either<AppError, BuiltList<User>> toUsers(dynamic list) { ... }

Either<AppError, BuiltList<User>> usersEither = await Either.futureBinding(
  (effect) async {
    // Left from either operation exits this outer scope immediately.
    final dynamic json = await httpGetAsEither(
      'https://jsonplaceholder.typicode.com/users',
    ).bind(effect);
    final BuiltList<User> users = toUsers(json).bind(effect);
    return users;
  },
);
```

---

### 6. Pipelines on `Future<Either<L, R>>`

These extensions keep the outer `Future` and operate on the `Right` inside its
`Either`. A `Left` skips the callback and passes through unchanged. An error
from the source future or callback remains a future error.

| Receiver                   | Method                                                                                                                                 | Right-side operation                                      |
|----------------------------|----------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| `Future<Either<L, R>>`     | [`thenMapEither`](https://pub.dev/documentation/dart_either/latest/dart_either/AsyncMapFutureExtension/thenMapEither.html)             | `R -> FutureOr<C>`, then wrap the result in `Right<C>`     |
| `Future<Either<L, R>>`     | [`thenFlatMapEither`](https://pub.dev/documentation/dart_either/latest/dart_either/AsyncFlatMapFutureExtension/thenFlatMapEither.html) | `R -> FutureOr<Either<L, C>>`, without nesting the result  |

Conceptually, these are `map` and `flatMap` for the concrete composition of
`Future` and `Either`. The names make the layers explicit: `then` signals that
the operation runs after the outer future completes, the middle verb describes
the right-side operation, and the `Either` suffix distinguishes these helpers
from operations on a plain `Future`.

Libraries with higher-kinded types can wrap the same shape in a monad
transformer. [Cats `EitherT`](https://typelevel.org/cats/datatypes/eithert.html),
for example, wraps `F[Either[E, A]]` and offers `map`/`flatMap` together with
more specific variants. The corresponding Cats name depends on the callback
shape: synchronous and asynchronous `thenMapEither` resemble `map` and
`semiflatMap`; synchronous and asynchronous `thenFlatMapEither` resemble
`subflatMap` and `flatMapF`. They are still the map-like and flatMap-like
operations exposed by this concrete Dart API, rather than one-to-one copies of
the Cats method names.
The corresponding standard Haskell transformer is
[`ExceptT e m a`](https://downloads.haskell.org/~ghc/9.12.2/docs/libraries/transformers-0.6.1.2-1307/Control-Monad-Trans-Except.html),
which wraps `m (Either e a)` and composes through `fmap` and `(>>=)`.
`dart_either` does not emulate higher-kinded types or expose an `EitherT`, so it
provides concrete, discoverable extensions for `Future<Either<L, R>>` instead.

Use these extensions when a short pipeline reads clearly. For a longer flow
where later `Either`-producing operations depend on earlier results,
`Either.futureBinding` keeps the code flat and avoids nested callbacks. It also
provides the same `Left` short-circuiting while allowing ordinary awaited
values, guards, and local variables in direct `async`/`await` style.
`Either.binding` is the synchronous counterpart and does not operate on
`Future<Either>`.

The shortened example below uses the same
[shared model](https://github.com/hoc081098/dart_either/blob/master/example/lib/http_example/shared_model.dart)
as the [complete runnable pipeline example](https://github.com/hoc081098/dart_either/blob/master/example/lib/http_example/http_either_chain.dart).

```dart
// 1) Define a reusable pipeline. thenFlatMapEither is used when the next
// operation already returns Either (or Future<Either>), so no nested Either
// is created.
Future<Either<AppError, dynamic>> httpGetAsEither(String uriString) {
  Either<AppError, dynamic> toJson(http.Response response) {
    final int statusCode = response.statusCode;
    final String body = response.body;

    return statusCode >= 200 && statusCode < 300
        ? Either<AppError, dynamic>.tryCatch(
            action: () => jsonDecode(body),
            errorMapper: toAppError('jsonDecode: body=$body'),
          )
        : Either<AppError, dynamic>.left(
            AppError(
              HttpException(
                'statusCode=$statusCode, body=$body',
                uri: response.request?.url,
              ),
              StackTrace.current,
              'statusCode: $statusCode',
            ),
          );
  }

  Future<Either<AppError, http.Response>> httpGet(Uri uri) =>
      Either.tryCatchAsync(
        action: () => http.get(uri),
        errorMapper: toAppError('http.get($uri)'),
      );

  final Future<Either<AppError, Uri>> uri = Future.value(
    Either.tryCatch(
      action: () => Uri.parse(uriString),
      errorMapper: toAppError('Parse $uriString'),
    ),
  );

  return uri.thenFlatMapEither(httpGet).thenFlatMapEither(toJson);
}

Either<AppError, BuiltList<User>> toUsers(dynamic list) { ... }

// 2) thenMapEither transforms a successful value. thenFlatMapEither then
// chains toUsers, which already returns Either, without nesting the result.
final Either<AppError, BuiltList<User>> usersEither =
    await httpGetAsEither('https://jsonplaceholder.typicode.com/users')
    .thenMapEither((dynamic json) => json as List)
    .thenFlatMapEither(toUsers);
```

---

## References

- [Working with typed errors - Arrow](https://arrow-kt.io/learn/typed-errors/working-with-typed-errors/)
- [Either and Ior - Arrow](https://arrow-kt.io/learn/typed-errors/wrappers/either-and-ior/)
- [From Either to Raise - Arrow](https://arrow-kt.io/learn/typed-errors/from-either-to-raise/)

---

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/hoc081098/dart_either/issues).

---

## License

```
MIT License

Copyright (c) 2021-2026 Petrus Nguyễn Thái Học
```
