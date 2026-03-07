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
  dart_either: ^2.1.0
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
final right = Either<String, int>.right(10); // Either.Right(10)

// Create an instance of [Left]
final left = Either<String, int>.left('none'); // Either.Left(none)

// Map the right value to a [String]
final mapRight = right.map((a) => 'String: $a'); // Either.Right(String: 10)

// Map the left value to a [int]
final mapLeft = right.mapLeft((a) => a.length); // Either.Right(10)

// Return [Left] if the function throws an error, otherwise return [Right]
final catchError = Either.catchError(
  (e, s) => 'Error: $e',
  () => int.parse('invalid'),
);
// Either.Left(Error: FormatException: Invalid radix-10 number (at character 1)
// invalid
// ^
// )

// 2) Operations
// Extract the value from [Either]
final value1 = right.getOrDefault(-1); // 10
final value2 = right.getOrHandle((l) => -1); // 10

// Chain computations
final flatMap = right.flatMap((a) => Either.right(a + 10)); // Either.Right(20)
final combined = right.combine(
  Either<String, int>.right(5),
  combineLeft: (a, b) => '$a,$b',
  combineRight: (a, b) => a + b,
); // Either.Right(15)
final flattened = Either<String, Either<String, int>>.right(
  Either<String, int>.right(10),
).flatten(); // Either.Right(10)
final merged = Either<int, int>.right(10).merge(); // 10

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
final nullableValue = right.getOrNull(); // 10
final leftValue = left.leftOrNull(); // 'none'
print(leftValue); // 'none'
print(nullableValue); // 10
```

</details>

---

## API Reference

> Full API docs: https://pub.dev/documentation/dart_either/latest/dart_either/

### 1. Creation

#### 1.1. Factory constructors

| Constructor                                                                                                       | Description                 |
|-------------------------------------------------------------------------------------------------------------------|-----------------------------|
| [`Either.left`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.left.html)             | Creates a `Left` value      |
| [`Either.right`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.right.html)           | Creates a `Right` value     |
| [`Either.binding`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.binding.html)       | Sync monad comprehension    |
| [`Either.catchError`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.catchError.html) | Wraps a throwing expression |
| [`Left`](https://pub.dev/documentation/dart_either/latest/dart_either/Left/Left.html)                             | Direct `Left` constructor   |
| [`Right`](https://pub.dev/documentation/dart_either/latest/dart_either/Right/Right.html)                          | Direct `Right` constructor  |

```dart
// 1) Create Left/Right
final left = Either<Object, String>.left('Left value');
// or: Left<Object, String>('Left value')

final right = Either<Object, int>.right(1);
// or: Right<Object, int>(1)

// 2) Sync monad comprehension (short-circuits on first Left)
Either<Object, String>.binding((e) {
  final String s = left.bind(e);
  final int i = right.bind(e);
  return '$s $i';
});

// 3) Catch thrown exception into Left
Either.catchError(
  (e, s) => 'Error: $e',
  () => int.parse('invalid'),
);
```

#### 1.2. Static methods

| Method                                                                                                                 | Description                              |
|------------------------------------------------------------------------------------------------------------------------|------------------------------------------|
| [`Either.catchFutureError`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/catchFutureError.html) | Wraps an async throwing expression       |
| [`Either.catchStreamError`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/catchStreamError.html) | Wraps a stream that may throw            |
| [`Either.fromNullable`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/fromNullable.html)         | Converts a nullable value                |
| [`Either.futureBinding`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/futureBinding.html)       | Async monad comprehension                |
| [`Either.parSequenceN`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/parSequenceN.html)         | Parallel sequence with concurrency limit |
| [`Either.parTraverseN`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/parTraverseN.html)         | Parallel traverse with concurrency limit |
| [`Either.sequence`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/sequence.html)                 | Sequences a list of `Either`s            |
| [`Either.traverse`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/traverse.html)                 | Maps + sequences a list                  |

```dart
import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:http/http.dart' as http;

// 1) Either.catchFutureError
Future<Either<String, http.Response>> eitherFuture = Either.catchFutureError(
  (e, s) => 'Error: $e',
  () async {
    final uri = Uri.parse('https://pub.dev/packages/dart_either');
    return http.get(uri);
  },
);
(await eitherFuture).fold(ifLeft: print, ifRight: print);


// 2) Either.catchStreamError
Stream<int> genStream() async* {
  for (var i = 0; i < 5; i++) {
    yield i;
  }
  throw Exception('Fatal');
}
Stream<Either<String, int>> eitherStream = Either.catchStreamError(
  (e, s) => 'Error: $e',
  genStream(),
);
eitherStream.listen(print);


// 3) Either.fromNullable
Either.fromNullable<int>(null); // Left(null)
Either.fromNullable<int>(1);    // Right(1)


// 4) Either.futureBinding
String url1 = 'url1';
String url2 = 'url2';
Either.futureBinding<String, http.Response>((e) async {
  final response = await Either.catchFutureError(
    (e, s) => 'Get $url1: $e',
    () async {
      final uri = Uri.parse(url1);
      return http.get(uri);
    },
  ).bind(e);

  final id = Either.catchError(
    (e, s) => 'Parse $url1 body: $e',
    () => jsonDecode(response.body)['id'] as String,
  ).bind(e);

  return await Either.catchFutureError(
    (e, s) => 'Get $url2: $e',
    () async {
      final uri = Uri.parse('$url2?id=$id');
      return http.get(uri);
    },
  ).bind(e);
});


// 5) Either.sequence
List<Either<String, http.Response>> eithers = await Future.wait(
  [1, 2, 3, 4, 5].map((id) {
    final url = 'url?id=$id';
    return Either.catchFutureError(
      (e, s) => 'Get $url: $e',
      () async {
        final uri = Uri.parse(url);
        return http.get(uri);
      },
    );
  }),
);
Either<String, BuiltList<http.Response>> sequencedResponses = Either.sequence(
  eithers,
);


// 6) Either.traverse
Either<String, BuiltList<Uri>> urisEither = Either.traverse(
  ['url1', 'url2', '::invalid::'],
  (String uriString) => Either.catchError(
    (e, s) => 'Failed to parse $uriString: $e',
    () => Uri.parse(uriString),
  ),
); // Left(FormatException('Failed to parse ::invalid:::...'))


// 7) Either.parSequenceN
Future<Either<String, BuiltList<int>>> parallelSequence = Either.parSequenceN(
  functions: [
    () async => fetchNumber(1),
    () async => fetchNumber(2),
    () async => fetchNumber(3),
  ],
  maxConcurrent: 2,
);

// 8) Either.parTraverseN
Future<Either<String, BuiltList<int>>> parallelTraverse = Either.parTraverseN(
  values: [1, 2, 3],
  mapper: (id) => () async => fetchNumber(id),
  maxConcurrent: 2,
);
```

#### 1.3. Extension methods

| Extension                                                                                                                           | Description                                    |
|-------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| [`Stream.toEitherStream`](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherStreamExtension/toEitherStream.html) | Converts a stream, catching errors into `Left` |
| [`Future.toEitherFuture`](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherFutureExtension/toEitherFuture.html) | Converts a future, catching errors into `Left` |
| [`T.left`](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherObjectExtension/left.html)                          | Wraps any value as `Left`                      |
| [`T.right`](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherObjectExtension/right.html)                        | Wraps any value as `Right`                     |

```dart
// 1) Stream.toEitherStream
Stream<int> genStream() async* {
  for (var i = 0; i < 5; i++) {
    yield i;
  }
  throw Exception('Fatal');
}
Stream<Either<String, int>> eitherStream =
    genStream().toEitherStream((e, s) => 'Error: $e');
eitherStream.listen(print);


// 2) Future.toEitherFuture
Future<Either<Object, int>> f1 =
    Future<int>.error('An error').toEitherFuture((e, s) => e);
Future<Either<Object, int>> f2 =
    Future<int>.value(1).toEitherFuture((e, s) => e);
await f1; // Left('An error')
await f2; // Right(1)


// 3) T.left / T.right
Either<int, String> left = 1.left<String>();
Either<String, int> right = 2.right<String>();
```

---

### 2. Operations

| Method                                                                                                                 | Description                                   |
|------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------|
| [`isLeft`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isLeft.html)                            | Returns `true` if this is a `Left`            |
| [`isRight`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isRight.html)                          | Returns `true` if this is a `Right`           |
| [`fold`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/fold.html)                                | Applies one of two functions based on variant |
| [`foldLeft`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/foldLeft.html)                        | Left fold with an initial value               |
| [`swap`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/swap.html)                                | Swaps `Left` and `Right`                      |
| [`onLeft`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/onLeft.html)                            | Side-effect on `Left`                         |
| [`onRight`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/onRight.html)                          | Side-effect on `Right`                        |
| [`map`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/map.html)                                  | Transforms the `Right` value                  |
| [`mapLeft`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/mapLeft.html)                          | Transforms the `Left` value                   |
| [`flatMap`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/flatMap.html)                          | Chains computations                           |
| [`bimap`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/bimap.html)                              | Transforms both sides                         |
| [`combine`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/combine.html)                          | Combines two `Either` values                  |
| [`isRightAnd`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isRightAnd.html)                    | Tests the `Right` value with a predicate      |
| [`all`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/all.html)                                  | Returns `true` for `Left` or if `Right` matches the predicate |
| [`getOrDefault`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/getOrDefault.html)                | Extracts `Right` or falls back to an eager default value |
| [`getOrNull`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/getOrNull.html)                      | Extracts `Right` or returns `null`            |
| [`leftOrNull`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/leftOrNull.html)                    | Extracts `Left` or returns `null`             |
| [`getOrHandle`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/getOrHandle.html)                  | Extracts `Right` or maps `Left` to a value    |
| [`flatten`](https://pub.dev/documentation/dart_either/latest/dart_either/FlattenEitherExtension/flatten.html)          | Flattens nested `Either`                      |
| [`merge`](https://pub.dev/documentation/dart_either/latest/dart_either/MergeEitherExtension/merge.html)                | Extracts value when both sides have same type |
| [`findOrNull`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/findOrNull.html)                    | Finds `Right` matching a predicate            |
| [`when`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/when.html)                                | Pattern-match returning the matched value     |
| [`handleErrorWith`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/handleErrorWith.html)          | Recovers from `Left` with a new `Either`      |
| [`handleError`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/handleError.html)                  | Recovers from `Left` with a new `Right` value |
| [`redeem`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/redeem.html)                            | Maps both sides to the same type              |
| [`redeemWith`](https://pub.dev/documentation/dart_either/latest/dart_either/Either/redeemWith.html)                    | Maps both sides to a new `Either`             |
| [`toFuture`](https://pub.dev/documentation/dart_either/latest/dart_either/AsFutureEitherExtension/toFuture.html)       | Converts to a `Future`                        |
| [`getOrThrow`](https://pub.dev/documentation/dart_either/latest/dart_either/GetOrThrowEitherExtension/getOrThrow.html) | Extracts `Right` or throws the `Left` value   |

```dart
final ok = Either<String, int>.right(10);
final err = Either<String, int>.left('boom');

// Predicates
ok.isRightAnd((v) => v > 0); // true
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

> Deprecated aliases: `tapLeft -> onLeft`, `tap -> onRight`, `orNull -> getOrNull`, `exists -> isRightAnd`.
> `getOrElse` is deprecated. Prefer `getOrDefault(<value>)` for eager fallback, or `getOrHandle((_) => <value>)` for lazy fallback.

---

### 3. Extensions on `Future<Either<L, R>>`

| Method                                                                                                                                 | Description                           |
|----------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------|
| [`thenFlatMapEither`](https://pub.dev/documentation/dart_either/latest/dart_either/AsyncFlatMapFutureExtension/thenFlatMapEither.html) | Async `flatMap` on a `Future<Either>` |
| [`thenMapEither`](https://pub.dev/documentation/dart_either/latest/dart_either/AsyncMapFutureExtension/thenMapEither.html)             | Async `map` on a `Future<Either>`     |

```dart
// 1) Define a reusable async pipeline with thenFlatMapEither / thenMapEither
Future<Either<AsyncError, dynamic>> httpGetAsEither(String uriString) {
  Either<AsyncError, dynamic> toJson(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300
          ? Either<AsyncError, dynamic>.catchError(
              toAsyncError,
              () => jsonDecode(response.body),
            )
          : AsyncError(
              HttpException(
                'statusCode=${response.statusCode}, body=${response.body}',
                uri: response.request?.url,
              ),
              StackTrace.current,
            ).left<dynamic>();

  Future<Either<AsyncError, http.Response>> httpGet(Uri uri) =>
      Either.catchFutureError(toAsyncError, () => http.get(uri));

  final uri =
      Future.value(Either.catchError(toAsyncError, () => Uri.parse(uriString)));

  return uri.thenFlatMapEither(httpGet).thenFlatMapEither<dynamic>(toJson);
}

Either<AsyncError, BuiltList<User>> toUsers(List list) { ... }

// 2) Build end-to-end flow
Either<AsyncError, BuiltList<User>> usersEither = await httpGetAsEither(
        'https://jsonplaceholder.typicode.com/users')
    .thenMapEither((dynamic json) => json as List)
    .thenFlatMapEither(toUsers);
```

---

### 4. Monad comprehensions

Use `Either.binding` (sync) or `Either.futureBinding` (async) for do-notation style sequential
computations that short-circuit on the first `Left`.

```dart
// 1) Define a reusable async pipeline with Either.futureBinding
Future<Either<AsyncError, dynamic>> httpGetAsEither(String uriString) =>
    Either.futureBinding<AsyncError, dynamic>((e) async {
      final uri =
          Either.catchError(toAsyncError, () => Uri.parse(uriString)).bind(e);

      final response = await Either.catchFutureError(
        toAsyncError,
        () => http.get(uri),
      ).bind(e);

      e.ensure(
        response.statusCode >= 200 && response.statusCode < 300,
        () => AsyncError(
          HttpException(
            'statusCode=${response.statusCode}, body=${response.body}',
            uri: response.request?.url,
          ),
          StackTrace.current,
        ),
      );

      return Either<AsyncError, dynamic>.catchError(
        toAsyncError,
        () => jsonDecode(response.body),
      ).bind(e);
    });

Either<AsyncError, BuiltList<User>> toUsers(List list) { ... }

// 2) Compose another flow by binding previous steps
Either<AsyncError, BuiltList<User>> usersEither = await Either.futureBinding(
  (e) async {
    final dynamic json =
        await httpGetAsEither('https://jsonplaceholder.typicode.com/users')
            .bind(e);
    final BuiltList<User> users = toUsers(json as List).bind(e);
    return users;
  },
);
```

---

## References

- [Functional Error Handling — Arrow-kt](https://arrow-kt.io/docs/patterns/error_handling/)
- [Monad — Arrow-kt](https://arrow-kt.io/docs/patterns/monads/)
- [Monad Comprehensions — Arrow-kt](https://arrow-kt.io/docs/patterns/monad_comprehensions/)

---

## Features and bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/hoc081098/dart_either/issues).

---

## License

```
MIT License

Copyright (c) 2021-2026 Petrus Nguyễn Thái Học
```
