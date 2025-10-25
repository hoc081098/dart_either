# dart_either

# Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

![Dart CI](https://github.com/hoc081098/dart_either/workflows/Dart%20CI/badge.svg)
[![Pub](https://img.shields.io/pub/v/dart_either)](https://pub.dev/packages/dart_either)
[![Pub](https://img.shields.io/pub/v/dart_either?include_prereleases)](https://pub.dev/packages/dart_either)
[![codecov](https://codecov.io/gh/hoc081098/dart_either/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/dart_either)
[![GitHub](https://img.shields.io/github/license/hoc081098/dart_either?color=4EB1BA)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fhoc081098%2Fdart_either&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

**Either monad for Dart and Flutter** — A lightweight, type-safe library for functional error handling and railway-oriented programming.

- ✅ Supports **Monad comprehensions** (both `sync` and `async` versions)
- ✅ Supports **async map** and **async flatMap** for seamless `Future<Either<L, R>>` operations
- ✅ Type-safe alternative to nullable values and exceptions
- ✅ Fully documented with comprehensive examples

**Credits:** Ported and adapted from [Λrrow-kt](https://github.com/arrow-kt/arrow).

---

**Support the project:**  
If you find this library helpful, consider [buying me a coffee](https://www.buymeacoffee.com/hoc081098)! ☕

<a href="https://www.buymeacoffee.com/hoc081098" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

---

## Why Choose dart_either?

Many developers import large functional programming libraries like [dartz](https://pub.dev/packages/dartz) or [fpdart](https://pub.dev/packages/fpdart) but only use the `Either` class. This library provides a focused, lightweight solution.

### Key Advantages

- **📦 Lightweight**: Focused solely on `Either` — no unnecessary dependencies
- **📖 Complete Documentation**: Every method includes detailed documentation and examples
- **🔄 Monad Comprehensions**: Full support for both sync and async comprehensions
- **⚡ Async Operations**: Built-in support for `async map` and `async flatMap` with `Future<Either<L, R>>`
- **🧪 Thoroughly Tested**: Comprehensive test coverage ensures reliability
- **🎯 Battle-Tested**: Inspired by proven implementations from [Λrrow-kt](https://github.com/arrow-kt/arrow) and [Scala Cats](https://typelevel.org/cats/typeclasses.html#type-classes-in-cats)

## 📦 Installation

Add `dart_either` to your `pubspec.yaml`:

```yaml
dependencies:
  dart_either: ^2.0.0
```

Then run:

```bash
dart pub get  # For Dart projects
flutter pub get  # For Flutter projects
```

## 📚 Documentation & Examples

- **API Documentation**: [pub.dev/documentation/dart_either](https://pub.dev/documentation/dart_either/latest/dart_either/dart_either-library.html)
- **Code Examples**: [example/lib](https://github.com/hoc081098/dart_either/tree/master/example/lib)
- **Flutter Example**: [node-auth-flutter-BLoC-pattern-RxDart](https://github.com/hoc081098/node-auth-flutter-BLoC-pattern-RxDart)

## 🎯 What is Either?

`Either` is a type that represents one of two possible values:
- **`Right<L, R>`**: Usually represents a successful or "desired" value
- **`Left<L, R>`**: Usually represents an error or "undesired" value

### Why Use Either?

Similar patterns exist in other languages:
- [Elm Result](https://package.elm-lang.org/packages/elm-lang/core/5.1.1/Result)
- [Haskell Data.Either](https://hackage.haskell.org/package/base-4.10.0.0/docs/Data-Either.html)
- [Rust Result](https://doc.rust-lang.org/std/result/enum.Result.html)

<details>
  <summary><b>📖 The Problem with Exceptions (click to expand)</b></summary>

In everyday programming, functions often fail. Querying a service might result in connection issues or unexpected JSON responses.

The traditional approach uses exceptions, but they have significant drawbacks:
- **Not tracked by the compiler**: You must dig through source code to find what exceptions might be thrown
- **No compile-time safety**: Forgetting to catch an exception leads to runtime crashes
- **Difficult to compose**: Combining exception-throwing functions becomes unwieldy

#### Example of Exception Hell

```dart
double throwsSomeStuff(int i) => throw UnimplementedError();

String throwsOtherThings(double d) => throw UnimplementedError();

List<int> moreThrowing(String s) => throw UnimplementedError();

List<int> magic(int i) => moreThrowing(throwsOtherThings(throwsSomeStuff(i)));
```

**Problems:**
- Which exceptions can `magic` throw? Impossible to tell from the types
- Where did an exception originate? Hard to track with identical exception types
- How to handle errors safely? Requires defensive programming everywhere

#### The Solution: Make Errors Explicit

`Either` makes errors explicit in the type system:
- Errors become part of your function's return type
- The compiler helps you handle all error cases
- Composing error-prone operations becomes straightforward

### How Either Works

`Either` is **right-biased**, meaning operations like `map` and `flatMap` work on the `Right` value and short-circuit on `Left`:

- **Right-biased operations**: `map`, `flatMap`, etc., only execute if the value is `Right`
- **Early termination**: The first `Left` encountered stops the computation chain
- **Type-safe**: The compiler ensures you handle both success and failure cases

#### Quick Example

```dart
/// Create instances
final right = Either<String, int>.right(10);        // Success: Right(10)
final left = Either<String, int>.left('error');     // Failure: Left(error)

/// Transform success values
final mapped = right.map((value) => value * 2);     // Right(20)
final leftMapped = left.map((value) => value * 2);  // Still Left(error)

/// Chain operations safely
final result = right
  .map((x) => x + 5)                                // Right(15)
  .flatMap((x) => Either.right(x * 2));             // Right(30)

/// Extract values safely
final value = right.getOrElse(() => -1);            // 10
final defaultValue = left.getOrElse(() => -1);      // -1

/// Pattern matching with Dart 3.0
print(switch (right) {
  Left(value: final l) => 'Error: $l',
  Right(value: final r) => 'Success: $r',
});  // Prints: Success: 10
```

</details>

### 🚀 Complete Example

```dart
/// Create an instance of Right
final right = Either<String, int>.right(10);  // Either.Right(10)

/// Create an instance of Left
final left = Either<String, int>.left('none');  // Either.Left(none)

/// Map the right value to a String
final mapRight = right.map((a) => 'String: $a');  // Either.Right(String: 10)

/// Map the left value to an int (has no effect on Right)
final mapLeft = right.mapLeft((a) => a.length);  // Either.Right(10)

/// Catch errors and return Either
final catchError = Either.catchError(
  (e, s) => 'Error: $e',
  () => int.parse('invalid'),
);
// Returns: Either.Left(Error: FormatException: Invalid radix-10 number...)

/// Extract values
final value1 = right.getOrElse(() => -1);        // 10
final value2 = right.getOrHandle((l) => -1);     // 10

/// Chain computations
final flatMap = right.flatMap((a) => Either.right(a + 10));  // Either.Right(20)

/// Pattern matching with fold
right.fold(
  ifLeft: (l) => print('Left value: $l'),
  ifRight: (r) => print('Right value: $r'),
);  // Prints: Right value: 10

/// Pattern matching with when
right.when(
  ifLeft: (l) => print('Left: $l'),
  ifRight: (r) => print('Right: $r'),
);  // Prints: Right: Either.Right(10)

/// Or use Dart 3.0 switch expressions 🚀
print(switch (right) {
  Left() => 'Left: $right',
  Right() => 'Right: $right',
});  // Prints: Right: Either.Right(10)

/// Convert to nullable value
final nullableValue = right.orNull();  // 10
```

## 📖 Usage Guide

> **Full API documentation**: [pub.dev/documentation/dart_either](https://pub.dev/documentation/dart_either/latest/dart_either/dart_either-library.html)

### 1. Creating Either Instances

#### 1.1. Factory Constructors

Create `Either` instances directly using factory constructors:

- [Either.left](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.left.html) — Create a Left instance
- [Either.right](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.right.html) — Create a Right instance
- [Either.binding](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.binding.html) — Monad comprehension (sync)
- [Either.catchError](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.catchError.html) — Catch exceptions as Left
- [Left](https://pub.dev/documentation/dart_either/latest/dart_either/Left/Left.html) — Direct Left constructor
- [Right](https://pub.dev/documentation/dart_either/latest/dart_either/Right-class.html) — Direct Right constructor

```dart
// Create Left and Right instances
final left = Either<Object, String>.left('Left value');  // or Left<Object, String>('Left value')
final right = Either<Object, int>.right(1);              // or Right<Object, int>(1)

// Use binding for sync monad comprehensions
final result = Either<Object, String>.binding((e) {
  final String s = left.bind(e);
  final int i = right.bind(e);
  return '$s $i';
});  // Returns: Left('Left value')

// Catch exceptions safely
final parsed = Either.catchError(
  (e, s) => 'Parse error: $e',
  () => int.parse('invalid'),
);  // Returns: Left(FormatException(...))
```

#### 1.2. Static Methods

Advanced creation methods for complex scenarios:

- [Either.catchFutureError](https://pub.dev/documentation/dart_either/latest/dart_either/Either/catchFutureError.html) — Catch async errors
- [Either.catchStreamError](https://pub.dev/documentation/dart_either/latest/dart_either/Either/catchStreamError.html) — Catch stream errors
- [Either.fromNullable](https://pub.dev/documentation/dart_either/latest/dart_either/Either/fromNullable.html) — Convert nullable to Either
- [Either.futureBinding](https://pub.dev/documentation/dart_either/latest/dart_either/Either/futureBinding.html) — Monad comprehension (async)
- [Either.parSequenceN](https://pub.dev/documentation/dart_either/latest/dart_either/Either/parSequenceN.html) — Parallel sequence with concurrency limit
- [Either.parTraverseN](https://pub.dev/documentation/dart_either/latest/dart_either/Either/parTraverseN.html) — Parallel traverse with concurrency limit
- [Either.sequence](https://pub.dev/documentation/dart_either/latest/dart_either/Either/sequence.html) — Sequence a list of Either
- [Either.traverse](https://pub.dev/documentation/dart_either/latest/dart_either/Either/traverse.html) — Map and sequence

```dart
import 'package:http/http.dart' as http;

// Catch Future errors
Future<Either<String, http.Response>> fetchData = Either.catchFutureError(
  (e, s) => 'HTTP Error: $e',
  () async {
    final uri = Uri.parse('https://pub.dev/packages/dart_either');
    return http.get(uri);
  },
);
(await fetchData).fold(ifLeft: print, ifRight: print);

// Catch Stream errors
Stream<int> numberStream() async* {
  for (var i = 0; i < 5; i++) {
    yield i;
  }
  throw Exception('Stream error');
}

Stream<Either<String, int>> safeStream = Either.catchStreamError(
  (e, s) => 'Error: $e',
  numberStream(),
);
safeStream.listen(print);

// Convert nullable values
Either.fromNullable<int>(null);  // Left(null)
Either.fromNullable<int>(1);     // Right(1)

// Async monad comprehensions
String url1 = 'https://api.example.com/user';
String url2 = 'https://api.example.com/profile';

await Either.futureBinding<String, http.Response>((e) async {
  // Fetch first URL
  final response = await Either.catchFutureError(
    (e, s) => 'Failed to fetch $url1: $e',
    () => http.get(Uri.parse(url1)),
  ).bind(e);

  // Parse the user ID
  final id = Either.catchError(
    (e, s) => 'Failed to parse JSON: $e',
    () => jsonDecode(response.body)['id'] as String,
  ).bind(e);

  // Fetch second URL with the ID
  return await Either.catchFutureError(
    (e, s) => 'Failed to fetch $url2: $e',
    () => http.get(Uri.parse('$url2?id=$id')),
  ).bind(e);
});

// Sequence: Convert List<Either> to Either<List>
List<Either<String, http.Response>> responses = await Future.wait(
  [1, 2, 3].map((id) => Either.catchFutureError(
    (e, s) => 'Error fetching id $id: $e',
    () => http.get(Uri.parse('https://api.example.com/item/$id')),
  )),
);
Either<String, BuiltList<http.Response>> allResponses = Either.sequence(responses);

// Traverse: Map and sequence in one operation
Either<String, BuiltList<Uri>> parsedUris = Either.traverse(
  ['https://example.com', 'https://google.com', '::invalid::'],
  (String uriString) => Either.catchError(
    (e, s) => 'Failed to parse "$uriString": $e',
    () => Uri.parse(uriString),
  ),
);  // Returns: Left('Failed to parse "::invalid::": ...')
```

#### 1.3. Extension Methods

Convenient extensions for converting values to Either:

- [Stream.toEitherStream](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherStreamExtension/toEitherStream.html) — Convert stream to Either stream
- [Future.toEitherFuture](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherFutureExtension/toEitherFuture.html) — Convert future to Either future
- [T.left](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherObjectExtension/left.html) — Convert value to Left
- [T.right](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherObjectExtension/right.html) — Convert value to Right

```dart
// Convert Stream to Either Stream
Stream<int> numberStream() async* {
  for (var i = 0; i < 5; i++) {
    yield i;
  }
  throw Exception('Fatal error');
}

Stream<Either<String, int>> safeStream = 
  numberStream().toEitherStream((e, s) => 'Error: $e');
safeStream.listen(print);

// Convert Future to Either Future
Future<Either<Object, int>> safeFuture1 = 
  Future<int>.error('An error').toEitherFuture((e, s) => e);
Future<Either<Object, int>> safeFuture2 = 
  Future<int>.value(42).toEitherFuture((e, s) => e);
  
await safeFuture1;  // Left('An error')
await safeFuture2;  // Right(42)

// Convert values to Either
Either<int, String> left = 1.left<String>();      // Left(1)
Either<String, int> right = 2.right<String>();    // Right(2)
```

### 2. Working with Either

Common operations for transforming and extracting values:

**Type Checking:**
- [isLeft](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isLeft.html) / [isRight](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isRight.html) — Check the type

**Transformations:**
- [map](https://pub.dev/documentation/dart_either/latest/dart_either/Either/map.html) — Transform Right value
- [mapLeft](https://pub.dev/documentation/dart_either/latest/dart_either/Either/mapLeft.html) — Transform Left value
- [bimap](https://pub.dev/documentation/dart_either/latest/dart_either/Either/bimap.html) — Transform both sides
- [flatMap](https://pub.dev/documentation/dart_either/latest/dart_either/Either/flatMap.html) — Chain operations
- [swap](https://pub.dev/documentation/dart_either/latest/dart_either/Either/swap.html) — Swap Left and Right

**Side Effects:**
- [tap](https://pub.dev/documentation/dart_either/latest/dart_either/Either/tap.html) — Execute side effect on Right
- [tapLeft](https://pub.dev/documentation/dart_either/latest/dart_either/Either/tapLeft.html) — Execute side effect on Left

**Extraction:**
- [fold](https://pub.dev/documentation/dart_either/latest/dart_either/Either/fold.html) — Pattern match both cases
- [foldLeft](https://pub.dev/documentation/dart_either/latest/dart_either/Either/foldLeft.html) — Fold with accumulator
- [when](https://pub.dev/documentation/dart_either/latest/dart_either/Either/when.html) — Pattern match with void callbacks
- [getOrElse](https://pub.dev/documentation/dart_either/latest/dart_either/Either/getOrElse.html) — Get Right or default
- [getOrHandle](https://pub.dev/documentation/dart_either/latest/dart_either/Either/getOrHandle.html) — Get Right or handle Left
- [orNull](https://pub.dev/documentation/dart_either/latest/dart_either/Either/orNull.html) — Convert to nullable
- [getOrThrow](https://pub.dev/documentation/dart_either/latest/dart_either/GetOrThrowEitherExtension/getOrThrow.html) — Get Right or throw

**Predicates:**
- [exists](https://pub.dev/documentation/dart_either/latest/dart_either/Either/exists.html) — Check if Right matches predicate
- [all](https://pub.dev/documentation/dart_either/latest/dart_either/Either/all.html) — Check if all Right values match
- [findOrNull](https://pub.dev/documentation/dart_either/latest/dart_either/Either/findOrNull.html) — Find Right matching predicate

**Error Handling:**
- [handleError](https://pub.dev/documentation/dart_either/latest/dart_either/Either/handleError.html) — Recover from Left
- [handleErrorWith](https://pub.dev/documentation/dart_either/latest/dart_either/Either/handleErrorWith.html) — Recover with Either
- [redeem](https://pub.dev/documentation/dart_either/latest/dart_either/Either/redeem.html) — Transform to single value
- [redeemWith](https://pub.dev/documentation/dart_either/latest/dart_either/Either/redeemWith.html) — Transform to Either

**Conversion:**
- [toFuture](https://pub.dev/documentation/dart_either/latest/dart_either/AsFutureEitherExtension/toFuture.html) — Convert to Future

### 3. Async Operations on `Future<Either<L, R>>`

These extensions let you work with `Future<Either<L, R>>` without unwrapping:

- [thenMapEither](https://pub.dev/documentation/dart_either/latest/dart_either/AsyncMapFutureExtension/thenMapEither.html) — Map Right value asynchronously
- [thenFlatMapEither](https://pub.dev/documentation/dart_either/latest/dart_either/AsyncFlatMapFutureExtension/thenFlatMapEither.html) — Chain async Either operations

```dart
// Define error type
class AsyncError {
  final Object error;
  final StackTrace stackTrace;
  AsyncError(this.error, this.stackTrace);
}

AsyncError toAsyncError(Object e, StackTrace s) => AsyncError(e, s);

// Helper function to fetch and parse JSON
Future<Either<AsyncError, dynamic>> httpGetAsEither(String uriString) {
  // Parse JSON from response
  Either<AsyncError, dynamic> parseJson(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300
          ? Either<AsyncError, dynamic>.catchError(
              toAsyncError,
              () => jsonDecode(response.body),
            )
          : AsyncError(
              HttpException('HTTP ${response.statusCode}: ${response.body}'),
              StackTrace.current,
            ).left<dynamic>();

  // Make HTTP GET request
  Future<Either<AsyncError, http.Response>> httpGet(Uri uri) =>
      Either.catchFutureError(toAsyncError, () => http.get(uri));

  // Chain operations without unwrapping
  final uri = Future.value(
    Either.catchError(toAsyncError, () => Uri.parse(uriString))
  );

  return uri
    .thenFlatMapEither(httpGet)
    .thenFlatMapEither<dynamic>(parseJson);
}

// Usage example
class User { /* ... */ }
Either<AsyncError, BuiltList<User>> parseUsers(List list) { /* ... */ }

Either<AsyncError, BuiltList<User>> result = 
  await httpGetAsEither('https://jsonplaceholder.typicode.com/users')
    .thenMapEither((dynamic json) => json as List)
    .thenFlatMapEither(parseUsers);
```

### 4. Monad Comprehensions

Monad comprehensions provide a clean syntax for chaining multiple Either operations. Use `Either.binding` for sync operations and `Either.futureBinding` for async operations.

**Why use comprehensions?**
- More readable than nested `flatMap` chains
- Automatic short-circuiting on the first `Left`
- Looks like imperative code but maintains functional properties

```dart
// Async monad comprehension example
Future<Either<AsyncError, dynamic>> httpGetAsEither(String uriString) =>
    Either.futureBinding<AsyncError, dynamic>((e) async {
      // Parse URI (sync operation)
      final uri = Either.catchError(
        toAsyncError,
        () => Uri.parse(uriString),
      ).bind(e);

      // Fetch data (async operation)
      final response = await Either.catchFutureError(
        toAsyncError,
        () => http.get(uri),
      ).bind(e);

      // Validate response status
      e.ensure(
        response.statusCode >= 200 && response.statusCode < 300,
        () => AsyncError(
          HttpException('HTTP ${response.statusCode}: ${response.body}'),
          StackTrace.current,
        ),
      );

      // Parse JSON
      return Either<AsyncError, dynamic>.catchError(
        toAsyncError,
        () => jsonDecode(response.body),
      ).bind(e);
    });

class User { /* ... */ }
Either<AsyncError, BuiltList<User>> parseUsers(List list) { /* ... */ }

// Use the comprehension
Either<AsyncError, BuiltList<User>> result = 
  await Either.futureBinding((e) async {
    final dynamic json = await httpGetAsEither(
      'https://jsonplaceholder.typicode.com/users'
    ).bind(e);
    
    final BuiltList<User> users = parseUsers(json as List).bind(e);
    
    return users;
  });
```

---

## 📚 Additional Resources

### Learn More About Functional Error Handling

- [Functional Error Handling in Arrow-kt](https://arrow-kt.io/docs/patterns/error_handling/)
- [Understanding Monads](https://arrow-kt.io/docs/patterns/monads/)
- [Monad Comprehensions Explained](https://arrow-kt.io/docs/patterns/monad_comprehensions/)

---

## 🐛 Issues & Contributions

Found a bug or have a feature request?  
Please file an issue at the [issue tracker](https://github.com/hoc081098/dart_either/issues).

Contributions are welcome! Feel free to open a pull request.

---

## 📄 License

```
MIT License

Copyright (c) 2021-2024 Petrus Nguyễn Thái Học
```