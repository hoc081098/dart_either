/// **dart_either** - Type-safe functional error handling for Dart and Flutter
///
/// ### Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)
///
/// ## Overview
///
/// [Either] is a type that represents one of two possible values:
/// - [Right] — Usually represents a successful or "desired" value
/// - [Left] — Usually represents an error or "undesired" value
///
/// Similar patterns exist in other languages:
/// - [Elm Result](https://package.elm-lang.org/packages/elm-lang/core/5.1.1/Result)
/// - [Haskell Data.Either](https://hackage.haskell.org/package/base-4.10.0.0/docs/Data-Either.html)
/// - [Rust Result](https://doc.rust-lang.org/std/result/enum.Result.html)
///
/// ## The Problem with Exceptions
///
/// In everyday programming, functions often fail. Querying a service might result 
/// in connection issues or unexpected JSON responses.
///
/// The traditional approach uses exceptions, but they have significant drawbacks:
/// - **Not tracked by the compiler**: You must dig through source code to find 
///   what exceptions might be thrown
/// - **No compile-time safety**: Forgetting to catch an exception leads to runtime crashes
/// - **Difficult to compose**: Combining exception-throwing functions becomes unwieldy
///
/// ### Example of Exception Hell
///
/// ```dart
/// double throwsSomeStuff(int i) => throw UnimplementedError();
///
/// String throwsOtherThings(double d) => throw UnimplementedError();
///
/// List<int> moreThrowing(String s) => throw UnimplementedError();
///
/// List<int> magic(int i) => moreThrowing(throwsOtherThings(throwsSomeStuff(i)));
/// ```
///
/// **Problems:**
/// - Which exceptions can `magic` throw? Impossible to tell from the types
/// - Where did an exception originate? Hard to track with identical exception types
/// - How to handle errors safely? Requires defensive programming everywhere
///
/// ## The Solution: Make Errors Explicit
///
/// `Either` makes errors explicit in the type system:
/// - Errors become part of your function's return type
/// - The compiler helps you handle all error cases
/// - Composing error-prone operations becomes straightforward
///
/// ## How Either Works
///
/// `Either` is used to short-circuit a computation upon the first error.
/// By convention, the right side of an `Either` is used to hold successful values.
///
/// Because `Either` is **right-biased**, it is possible to define a `Monad` instance for it.
/// Since we only ever want the computation to continue in the case of [Right] 
/// (as captured by the right-bias nature), we fix the left type parameter and leave 
/// the right one free. So, the [Either.map] and [Either.flatMap] methods are right-biased.
///
/// ### Right-biased Operations
///
/// - Operations like [Either.map] and [Either.flatMap] only execute if the value is [Right]
/// - The first [Left] encountered stops the computation chain
/// - The compiler ensures you handle both success and failure cases
library dart_either;

export 'src/binding.dart';
export 'src/dart_either.dart';
export 'src/either_extensions.dart';
export 'src/extensions.dart';
