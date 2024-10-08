# dart_either

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

![Dart CI](https://github.com/hoc081098/dart_either/workflows/Dart%20CI/badge.svg)
[![Pub](https://img.shields.io/pub/v/dart_either)](https://pub.dev/packages/dart_either)
[![Pub](https://img.shields.io/pub/v/dart_either?include_prereleases)](https://pub.dev/packages/dart_either)
[![codecov](https://codecov.io/gh/hoc081098/dart_either/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/dart_either)
[![GitHub](https://img.shields.io/github/license/hoc081098/dart_either?color=4EB1BA)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fhoc081098%2Fdart_either&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

Either monad for Dart language and Flutter framework.
The library for error handling and railway oriented programming.
Supports `Monad comprehensions` (both `sync` and `async` versions).
Supports `async map` and `async flatMap` hiding the boilerplate of working with asynchronous computations `Future<Either<L, R>>`.
Error handler library for type-safe and easy work with errors on Dart and Flutter.
Either is an alternative to Nullable value and Exceptions.

## Credits: port and adapt from [Λrrow-kt](https://github.com/arrow-kt/arrow).

Liked some of my work? Buy me a coffee (or more likely a beer)

<a href="https://www.buymeacoffee.com/hoc081098" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-blue.png" alt="Buy Me A Coffee" height=64></a>

## Difference from other implementations ([dartz](https://pub.dev/packages/dartz) and [fpdart](https://pub.dev/packages/fpdart))

I have seen a lot of people importing whole libraries such as [dartz](https://pub.dev/packages/dartz) and [fpdart](https://pub.dev/packages/fpdart), ...
but they only use `Either` class :). So I decided to write, port and adapt `Either` class from [Λrrow-kt](https://github.com/arrow-kt/arrow).

- Inspired by [Λrrow-kt](https://github.com/arrow-kt/arrow), [Scala Cats](https://typelevel.org/cats/typeclasses.html#type-classes-in-cats).
- **Fully documented**, **tested** and **many examples**. Every method/function in this library is documented with examples.
- This library is **most complete** `Either` implementation, which supports **`Monad comprehensions` (both `sync` and `async` versions)**,
  and supports `async map` and `async flatMap` hiding the boilerplate of working with asynchronous computations `Future<Either<L, R>>`.
- Very **lightweight** and **simple** library (compare to [dartz](https://pub.dev/packages/dartz)).

## Getting started

In your Dart/Flutter project, add the dependency to your `pubspec.yaml`

```yaml
dependencies:
  dart_either: ^2.0.0
```

## Documentation & example

 - **Documentation**: https://pub.dev/documentation/dart_either/latest/dart_either/dart_either-library.html
 - **Example**: https://github.com/hoc081098/dart_either/tree/master/example/lib
 - **Flutter Example**: https://github.com/hoc081098/node-auth-flutter-BLoC-pattern-RxDart

## Either monad

`Either` is a type that represents either `Right` (usually represent a "desired" value)
or `Left` (usually represent a "undesired" value or error value).

- [Elm Result](https://package.elm-lang.org/packages/elm-lang/core/5.1.1/Result).
- [Haskell Data.Either](https://hackage.haskell.org/package/base-4.10.0.0/docs/Data-Either.html).
- [Rust Result](https://doc.rust-lang.org/std/result/enum.Result.html).

<details>
  <summary>Click to expand</summary>

In day-to-day programming, it is fairly common to find ourselves writing functions that can fail.
For instance, querying a service may result in a connection issue, or some unexpected `JSON` response.

To communicate these errors, it has become common practice to throw exceptions; however,
exceptions are not tracked in any way, shape, or form by the compiler. To see what
kind of exceptions (if any) a function may throw, we have to dig through the source code.
Then, to handle these exceptions, we have to make sure we catch them at the call site. This
all becomes even more unwieldy when we try to compose exception-throwing procedures.

```dart
double throwsSomeStuff(int i) => throw UnimplementedError();
///
String throwsOtherThings(double d) => throw UnimplementedError();
///
List<int> moreThrowing(String s) => throw UnimplementedError();
///
List<int> magic(int i) => moreThrowing( throwsOtherThings( throwsSomeStuff(i) ) );
```

Assume we happily throw exceptions in our code. Looking at the types of the functions above,
any could throw a number of exceptions -- we do not know. When we compose, exceptions from any of the constituent
functions can be thrown. Moreover, they may throw the same kind of exception
(e.g., `ArgumentError`) and, thus, it gets tricky tracking exactly where an exception came from.

How then do we communicate an error? By making it explicit in the data type we return.

`Either` is used to short-circuit a computation upon the first error.
By convention, the right side of an `Either` is used to hold successful values.

Because `Either` is right-biased, it is possible to define a `Monad` instance for it.
Since we only ever want the computation to continue in the case of `Right` (as captured by the right-bias nature),
we fix the left type parameter and leave the right one free. So, the `map` and `flatMap` methods are right-biased.

Example:
```dart
/// Create an instance of [Right]
final right = Either<String, int>.right(10); // Either.Right(10)

/// Create an instance of [Left]
final left = Either<String, int>.left('none'); // Either.Left(none)

/// Map the right value to a [String]
final mapRight = right.map((a) => 'String: $a'); // Either.Right(String: 10)

/// Map the left value to a [int]
final mapLeft = right.mapLeft((a) => a.length); // Either.Right(10)

/// Return [Left] if the function throws an error.
/// Otherwise return [Right].
final catchError = Either.catchError(
  (e, s) => 'Error: $e',
  () => int.parse('invalid'),
);
// Either.Left(Error: FormatException: Invalid radix-10 number (at character 1)
// invalid
// ^
// )

/// Extract the value from [Either]
final value1 = right.getOrElse(() => -1); // 10
final value2 = right.getOrHandle((l) => -1); // 10

/// Chain computations
final flatMap = right.flatMap((a) => Either.right(a + 10)); // Either.Right(20)

/// Pattern matching
right.fold(
  ifLeft: (l) => print('Left value: $l'),
  ifRight: (r) => print('Right value: $r'),
); // Right: 10
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

/// Convert to nullable value
final nullableValue = right.orNull(); // 10
```

</details>

## Use - [Documentation](https://pub.dev/documentation/dart_either/latest/dart_either/dart_either-library.html)

### 1. Creation

#### 1.1. Factory constructors

- [Either.left](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.left.html)
- [Either.right](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.right.html)
- [Either.binding](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.binding.html)
- [Either.catchError](https://pub.dev/documentation/dart_either/latest/dart_either/Either/Either.catchError.html)
- [Left](https://pub.dev/documentation/dart_either/latest/dart_either/Left/Left.html)
- [Right](https://pub.dev/documentation/dart_either/latest/dart_either/Right-class.html)

```dart
// Left('Left value')
final left = Either<Object, String>.left('Left value'); // or Left<Object, String>('Left value');

// Right(1)
final right = Either<Object, int>.right(1); // or Right<Object, int>(1);

// Left('Left value')
Either<Object, String>.binding((e) {
  final String s = left.bind(e);
  final int i = right.bind(e);
  return '$s $i';
});

// Left(FormatException(...))
Either.catchError(
  (e, s) => 'Error: $e',
  () => int.parse('invalid'),
);
```

#### 1.2. Static methods

- [Either.catchFutureError](https://pub.dev/documentation/dart_either/latest/dart_either/Either/catchFutureError.html)
- [Either.catchStreamError](https://pub.dev/documentation/dart_either/latest/dart_either/Either/catchStreamError.html)
- [Either.fromNullable](https://pub.dev/documentation/dart_either/latest/dart_either/Either/fromNullable.html)
- [Either.futureBinding](https://pub.dev/documentation/dart_either/latest/dart_either/Either/futureBinding.html)
- [Either.parSequenceN](https://pub.dev/documentation/dart_either/latest/dart_either/Either/parSequenceN.html)
- [Either.parTraverseN](https://pub.dev/documentation/dart_either/latest/dart_either/Either/parTraverseN.html)
- [Either.sequence](https://pub.dev/documentation/dart_either/latest/dart_either/Either/sequence.html)
- [Either.traverse](https://pub.dev/documentation/dart_either/latest/dart_either/Either/traverse.html)

```dart
import 'package:http/http.dart' as http;

/// Either.catchFutureError
Future<Either<String, http.Response>> eitherFuture = Either.catchFutureError(
  (e, s) => 'Error: $e',
  () async {
    final uri = Uri.parse('https://pub.dev/packages/dart_either');
    return http.get(uri);
  },
);
(await eitherFuture).fold(ifLeft: print, ifRight: print);


/// Either.catchStreamError
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


/// Either.fromNullable
Either.fromNullable<int>(null); // Left(null)
Either.fromNullable<int>(1);    // Right(1)


/// Either.futureBinding
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


/// Either.sequence
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
Either<String, BuiltList<http.Response>> result = Either.sequence(eithers);


/// Either.traverse
Either<String, BuiltList<Uri>> urisEither = Either.traverse(
  ['url1', 'url2', '::invalid::'],
  (String uriString) => Either.catchError(
    (e, s) => 'Failed to parse $uriString: $e',
    () => Uri.parse(uriString),
  ),
); // Left(FormatException('Failed to parse ::invalid:::...'))
```

#### 1.3. Extension methods
- [Stream.toEitherStream](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherStreamExtension/toEitherStream.html)
- [Future.toEitherFuture](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherFutureExtension/toEitherFuture.html)
- [T.left](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherObjectExtension/left.html)
- [T.right](https://pub.dev/documentation/dart_either/latest/dart_either/ToEitherObjectExtension/right.html)

```dart
/// Stream.toEitherStream
Stream<int> genStream() async* {
  for (var i = 0; i < 5; i++) {
    yield i;
  }
  throw Exception('Fatal');
}
Stream<Either<String, int>> eitherStream = genStream().toEitherStream((e, s) => 'Error: $e');
eitherStream.listen(print);


/// Future.toEitherFuture
Future<Either<Object, int>> f1 = Future<int>.error('An error').toEitherFuture((e, s) => e);
Future<Either<Object, int>> f2 = Future<int>.value(1).toEitherFuture((e, s) => e);
await f1; // Left('An error')
await f2; // Right(1)


/// T.left, T.right
Either<int, String> left = 1.left<String>();
Either<String, int> right = 2.right<String>();
```

### 2. Operations

- [isLeft](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isLeft.html)
- [isRight](https://pub.dev/documentation/dart_either/latest/dart_either/Either/isRight.html)
- [fold](https://pub.dev/documentation/dart_either/latest/dart_either/Either/fold.html)
- [foldLeft](https://pub.dev/documentation/dart_either/latest/dart_either/Either/foldLeft.html)
- [swap](https://pub.dev/documentation/dart_either/latest/dart_either/Either/swap.html)
- [tapLeft](https://pub.dev/documentation/dart_either/latest/dart_either/Either/tapLeft.html)
- [tap](https://pub.dev/documentation/dart_either/latest/dart_either/Either/tap.html)
- [map](https://pub.dev/documentation/dart_either/latest/dart_either/Either/map.html)
- [mapLeft](https://pub.dev/documentation/dart_either/latest/dart_either/Either/mapLeft.html)
- [flatMap](https://pub.dev/documentation/dart_either/latest/dart_either/Either/flatMap.html)
- [bimap](https://pub.dev/documentation/dart_either/latest/dart_either/Either/bimap.html)
- [exists](https://pub.dev/documentation/dart_either/latest/dart_either/Either/exists.html)
- [all](https://pub.dev/documentation/dart_either/latest/dart_either/Either/all.html)
- [getOrElse](https://pub.dev/documentation/dart_either/latest/dart_either/Either/getOrElse.html)
- [orNull](https://pub.dev/documentation/dart_either/latest/dart_either/Either/orNull.html)
- [getOrHandle](https://pub.dev/documentation/dart_either/latest/dart_either/Either/getOrHandle.html)
- [findOrNull](https://pub.dev/documentation/dart_either/latest/dart_either/Either/findOrNull.html)
- [when](https://pub.dev/documentation/dart_either/latest/dart_either/Either/when.html)
- [handleErrorWith](https://pub.dev/documentation/dart_either/latest/dart_either/Either/handleErrorWith.html)
- [handleError](https://pub.dev/documentation/dart_either/latest/dart_either/Either/handleError.html)
- [redeem](https://pub.dev/documentation/dart_either/latest/dart_either/Either/redeem.html)
- [redeemWith](https://pub.dev/documentation/dart_either/latest/dart_either/Either/redeemWith.html)
- [toFuture](https://pub.dev/documentation/dart_either/latest/dart_either/AsFutureEitherExtension/toFuture.html)
- [getOrThrow](https://pub.dev/documentation/dart_either/latest/dart_either/GetOrThrowEitherExtension/getOrThrow.html)

### 3. Extensions on `Future<Either<L, R>>`.

- [thenFlatMapEither](https://pub.dev/documentation/dart_either/latest/dart_either/AsyncFlatMapFutureExtension/thenFlatMapEither.html)
- [thenMapEither](https://pub.dev/documentation/dart_either/latest/dart_either/AsyncMapFutureExtension/thenMapEither.html)

```dart
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

Either<AsyncError, BuiltList<User>> result = await httpGetAsEither('https://jsonplaceholder.typicode.com/users')
    .thenMapEither((dynamic json) => json as List)
    .thenFlatMapEither(toUsers);
```

### 4. Monad comprehensions

You can use `Monad comprehensions` via `Either.binding` and `Either.futureBinding`.

```dart
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
          toAsyncError, () => jsonDecode(response.body)).bind(e);
    });

Either<AsyncError, BuiltList<User>> toUsers(List list) { ... }

Either<AsyncError, BuiltList<User>> result = await Either.futureBinding((e) async {
  final dynamic json = await httpGetAsEither('https://jsonplaceholder.typicode.com/users').bind(e);
  final BuiltList<User> users = toUsers(json as List).bind(e);
  return users;
});
```

## References

- [Functional Error Handling](https://arrow-kt.io/docs/patterns/error_handling/)
- [Monad](https://arrow-kt.io/docs/patterns/monads/)
- [Monad Comprehensions](https://arrow-kt.io/docs/patterns/monad_comprehensions/)

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoc081098/dart_either/issues

## License

```
MIT License

Copyright (c) 2021-2024 Petrus Nguyễn Thái Học
```