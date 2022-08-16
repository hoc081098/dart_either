# dart_either

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

![Dart CI](https://github.com/hoc081098/dart_either/workflows/Dart%20CI/badge.svg)
[![Pub](https://img.shields.io/pub/v/dart_either)](https://pub.dev/packages/dart_either)
[![Pub](https://img.shields.io/pub/v/dart_either?include_prereleases)](https://pub.dev/packages/dart_either)
[![codecov](https://codecov.io/gh/hoc081098/dart_either/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/dart_either)
[![GitHub](https://img.shields.io/github/license/hoc081098/dart_either?color=4EB1BA)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-lints-40c4ff.svg)](https://pub.dev/packages/lints)
[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2Fhoc081098%2Fdart_either&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://hits.seeyoufarm.com)

Either monad for Dart language and Flutter framework. Supports `Monad comprehension` (both `sync` and `async` versions).

## Credits: port and adapt from [Λrrow-kt](https://github.com/arrow-kt/arrow).

Liked some of my work? Buy me a coffee (or more likely a beer)

[!["Buy Me A Coffee"](https://cdn.buymeacoffee.com/buttons/default-orange.png)](https://www.buymeacoffee.com/hoc081098)

## Difference from other implementations ([dartz](https://pub.dev/packages/dartz) and [fpdart](https://pub.dev/packages/fpdart))

I see a lot of people importing whole libraries such as [dartz](https://pub.dev/packages/dartz) and [fpdart](https://pub.dev/packages/fpdart), ...
but they only use `Either` class :). So I decided to write, port and adapt `Either` class from [Λrrow-kt](https://github.com/arrow-kt/arrow).

- Inspired by [Λrrow-kt](https://github.com/arrow-kt/arrow), [Scala Cats](https://typelevel.org/cats/typeclasses.html#type-classes-in-cats).
- **Fully documented**, **tested** and **many examples**. Every method/function in this library is documented with examples.
- This library is **most complete** `Either` implementation, which supports **`Monad comprehension` (both `sync` and `async` versions)**.
- Very **lightweight** and **simple** library (compare to [dartz](https://pub.dev/packages/dartz)).

## Either monad

`Either` is a type that represents either `Right` (usually represent a "desired" value)
or `Left` (usually represent a "undesired" value or error value).

- [Elm Result](http://package.elm-lang.org/packages/elm-lang/core/5.1.1/Result).
- [Haskell Data.Either](https://hackage.haskell.org/package/base-4.10.0.0/docs/Data-Either.html).
- [Rust Result](https://doc.rust-lang.org/std/result/enum.Result.html).

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
  final right = Either<String, int>.right(10);
  print(right); // Prints Either.Right(10)

  /// Create an instance of [Left]
  final left = Either<String, int>.left('none');
  print(left); // Prints Either.Left(none)

  /// Map the right value to a [String]
  final mapRight = right.map((a) => 'String: $a');
  print(mapRight); // Prints Either.Right(String: 10)

  /// Map the left value to a [int]
  final mapLeft = right.mapLeft((a) => a.length);
  print(mapLeft); // Prints Either.Right(10)

  /// Return [Left] if the function throws an error.
  /// Otherwise return [Right].
  final catchError = Either.catchError(
    (e, s) => 'Error: $e',
    () => int.parse('invalid'),
  );
  print(catchError);
  // Prints Either.Left(Error: FormatException: Invalid radix-10 number (at character 1)
  // invalid
  // ^
  // )

  /// Extract the value from [Either]
  final value1 = right.getOrElse(() => -1);
  final value2 = right.getOrHandle((l) => -1);
  print('$value1, $value2'); // Prints 10, 10

  /// Chain computations
  final flatMap = right.flatMap((a) => Either.right(a + 10));
  print(flatMap); // Prints Either.Right(20)

  /// Pattern matching
  right.fold(
    ifLeft: (l) => print('Left($l)'),
    ifRight: (r) => print('Right($r)'),
  ); // Prints Right(10)

  /// Convert to nullable value
  final nullableValue = right.orNull();
  print(nullableValue); // Prints 10
```

## Use - [Documentation](https://pub.dev/documentation/dart_either/1.0.0-beta02/dart_either/dart_either-library.html)

### Creation

#### Factory constructors.

- [Either.left](https://pub.dev/documentation/dart_either/1.0.0-beta02/dart_either/Either/Either.left.html)
- [Either.right](https://pub.dev/documentation/dart_either/1.0.0-beta02/dart_either/Either/Either.right.html)
- [Either.binding](https://pub.dev/documentation/dart_either/1.0.0-beta02/dart_either/Either/Either.binding.html)
- [Either.catchError](https://pub.dev/documentation/dart_either/1.0.0-beta02/dart_either/Either/Either.catchError.html)
- [Left](https://pub.dev/documentation/dart_either/1.0.0-beta02/dart_either/Left/Left.html)
- [Right](https://pub.dev/documentation/dart_either/1.0.0-beta02/dart_either/Right-class.html)

## Reference

- [Functional Error Handling](https://arrow-kt.io/docs/patterns/error_handling/)
- [Monad](https://arrow-kt.io/docs/patterns/monads/)
- [Monad Comprehensions](https://arrow-kt.io/docs/patterns/monad_comprehensions/)

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoc081098/dart_either/issues
