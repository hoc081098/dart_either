# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-09-01

### Changed

- **BREAKING**: Require Dart SDK `>=3.0.0 <4.0.0`
- **BREAKING**: Made `Either` a sealed class for exhaustive pattern matching
- **BREAKING**: Made `EitherEffect` a sealed class
- **BREAKING**: Made `ControlError` a final class

### Added

- ✨ **Dart 3.0 Pattern Matching**: Full support for exhaustive switch expressions
  ```dart
  final Either<String, int> either = Either.right(10);
  
  // Use the `when` method
  either.when(
    ifLeft: (l) => print('Left: $l'),
    ifRight: (r) => print('Right: $r'),
  ); // Prints: Right: Either.Right(10)
  
  // Or use Dart 3.0 switch expressions 🚀
  print(switch (either) {
    Left() => 'Left: $either',
    Right() => 'Right: $either',
  }); // Prints: Right: Either.Right(10)
  ```

## [1.0.0] - 2022-08-23

### Changed

- 🎉 First stable release
- Production-ready API with comprehensive test coverage

## [0.0.1] - 2021-04-27

### Added

- Initial version created by Stagehand
- Core `Either` monad implementation
- Support for `Left` and `Right` types
- Basic functional operations (map, flatMap, fold)

[2.0.0]: https://github.com/hoc081098/dart_either/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/hoc081098/dart_either/compare/v0.0.1...v1.0.0
[0.0.1]: https://github.com/hoc081098/dart_either/releases/tag/v0.0.1
