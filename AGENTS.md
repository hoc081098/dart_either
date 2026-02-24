# AGENTS.md — dart_either

## Project Overview

**dart_either** is a Dart library providing the `Either` monad for type-safe error handling and railway oriented programming.
It is published on [pub.dev](https://pub.dev/packages/dart_either) and authored by [Petrus Nguyễn Thái Học](https://github.com/hoc081098).

- **Language**: Dart (SDK `>=3.0.0 <4.0.0`)
- **Package manager**: `dart pub`
- **Repository**: https://github.com/hoc081098/dart_either

## Project Structure

```
lib/
  dart_either.dart              # Public library barrel file (exports all public APIs)
  src/
    dart_either.dart            # Core Either sealed class (Left, Right), constructors, instance methods, static methods, EitherEffect (monad comprehension), ControlError
    extensions.dart             # Extension methods: toEitherStream, toEitherFuture, thenFlatMapEither, thenMapEither, .left(), .right()
    either_extensions.dart      # Extension methods: toFuture, getOrThrow (require L extends Object)
    binding.dart                # Monad comprehension extensions: ensure, ensureNotNull, bindFuture, bind on Either, bind on Future<Either>
    utils/
      semaphore.dart            # Internal Semaphore utility (used by parSequenceN / parTraverseN)
test/
  dart_either_test.dart         # Main test file (comprehensive unit tests)
  semaphore_test.dart           # Tests for Semaphore utility
example/
  lib/
    dart_either_readme.dart     # README examples
    dart_either_styles.dart     # Usage style examples
    http_example/               # HTTP usage examples with Either
```

## Key Concepts

- **`Either<L, R>`**: A sealed class representing a disjunction — `Left(L)` for errors/undesired values, `Right(R)` for success/desired values.
- **Right-biased**: `map`, `flatMap`, and other operations act on the `Right` value. `Left` short-circuits the computation.
- **Monad comprehensions**: `Either.binding` (sync) and `Either.futureBinding` (async) provide do-notation style via `EitherEffect.bind`.
- **ControlError**: Internal error type used by monad comprehensions. Must NEVER be caught by user code.
- **ErrorMapper<T>**: `T Function(Object error, StackTrace stackTrace)` — maps thrown errors to the Left type.

## Coding Conventions

- **Dart 3 features**: Uses sealed classes, pattern matching (`switch` expressions with `case Left(value:)` / `case Right(value:)`).
- **Immutable**: `Either` is `@immutable` and `@sealed`. `Left` and `Right` are `@sealed` final-like classes.
- **Annotations**: 
  - Use `@useResult` **ONLY** on methods that return `Either<...>` or `Stream<Either<...>>`.
  - Do **NOT** use `@useResult` on:
    - Methods returning `Future<Either<...>>` (Future just needs `await`, no need to warn about assignment).
    - Methods returning generic types like `bool`, `R`, etc. (can be `void`).
    - Pattern matching methods like `fold`, `when` (often used for side effects with `void` return).
  - Use `@monadComprehensions` on bind-related methods.
  - Use `@experimental` for unstable APIs.
- **Documentation**: Every public member MUST have a doc comment with `///`. Include `### Example` code blocks in doc comments. This is enforced by the `public_member_api_docs` lint rule.
- **Imports**: Use `prefer_relative_imports` within `lib/src/`.
- **Linter**: Uses `package:lints/recommended.yaml` with additional rules — see `analysis_options.yaml`.
- **Style rules**: `prefer_final_locals`, `prefer_single_quotes`, `always_declare_return_types`, `unawaited_futures`.
- **Strong mode**: `implicit-casts: false`, `implicit-dynamic: false`.

## Dependencies

- **Runtime**: `meta` (annotations), `built_collection` (for `BuiltList` in `traverse`/`sequence` methods).
- **Dev**: `test` (unit testing), `lints` (analysis), `rxdart_ext` (used in tests).

## Common Commands

```bash
# Get dependencies
dart pub get

# Run all tests
dart test

# Run a specific test file
dart test test/dart_either_test.dart

# Analyze code (linting + static analysis)
dart analyze

# Format code
dart format .

# Check formatting
dart format --set-exit-if-changed .

# Dry-run publish
dart pub publish --dry-run
```

## Testing

- Tests are in the `test/` directory using `package:test`.
- Run with `dart test`.
- All public APIs should have corresponding tests.
- Test naming pattern: `group('MethodName', () { test('description', () { ... }); });`

## Guidelines for AI Agents

1. **Do NOT break the public API** — this is a published pub.dev package. Any breaking change requires a major version bump.
2. **Maintain full documentation** — all public members must have `///` doc comments with examples. The `public_member_api_docs` lint will fail otherwise.
3. **Use `@useResult` correctly** — ONLY on methods returning `Either<...>` or `Stream<Either<...>>`:
   - ✅ **DO** use: `Either<L, R>`, `Either<void, R>`, `Stream<Either<L, R>>`
   - ❌ **DON'T** use: `Future<Either<...>>` (just await), `bool`, generic `R`, `C fold<C>(...)`, etc.
   - **Examples with `@useResult`**: `map`, `flatMap`, `swap`, `left()`, `right()`, `toEitherStream`
   - **Examples without `@useResult`**: `toEitherFuture`, `fold`, `when`, `isLeft`, `exists`, `all`, `ensureNotNull`
4. **Use Dart 3 patterns** — prefer `switch` expressions and sealed class pattern matching over `is` type checks.
5. **Keep the library lightweight** — avoid adding unnecessary dependencies.
6. **Run `dart analyze` and `dart test`** after any change to verify correctness.
7. **Prefer `prefer_single_quotes`** — use single quotes for strings.
8. **Never catch `ControlError`** in library or user code (except in `Either.binding` / `Either.futureBinding` internals).
9. **Extension naming convention**: `<Purpose><Type>Extension` (e.g., `ToEitherStreamExtension`, `BindEitherExtension`).
10. **Test structure**: Mirror the source structure. Group tests by class/method name.

