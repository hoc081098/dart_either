# dart_either

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

![Dart CI](https://github.com/hoc081098/dart_either/workflows/Dart%20CI/badge.svg)
[![Pub](https://img.shields.io/pub/v/dart_either)](https://pub.dev/packages/dart_either)
[![Pub](https://img.shields.io/pub/v/dart_either?include_prereleases)](https://pub.dev/packages/dart_either)
[![codecov](https://codecov.io/gh/hoc081098/dart_either/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/dart_either)
[![GitHub](https://img.shields.io/github/license/hoc081098/dart_either?color=4EB1BA)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-pedantic-40c4ff.svg)](https://github.com/dart-lang/pedantic)


## Usage

A simple usage example:

```dart
import 'package:dart_either/dart_either.dart';

Either<EitherError<Object>, String> catchObject() {
  return Either.catchError(() {
    throw Exception('Test');
  });
}

Either<EitherError<Exception>, String> catchException() {
  return Either.catchError<Exception, String>(() {
    throw 'A string';
  });
}

Future<Either<Object, String>> catchObjectAsync() {
  return Either.catchFutureError(() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    throw Exception('Test 2');
  });
}

Future<Either<EitherError<Exception>, String>> catchExceptionAsync() {
  return Either.catchFutureError(() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    throw 'A string';
  });
}

Stream<Either<EitherError<Object>, int>> getStream() {
  return Stream.fromIterable([1, 2, 3, 4])
      .map((v) => v == 3 ? throw Exception('Error...') : v)
      .either();
}

void main() async {
  catchObject().fold((e) => print('Error: $e'), print);
  (await catchObjectAsync()).fold((e) => print('Error: $e'), print);

  try {
    catchException().fold((e) => print('Error: $e'), print);
  } catch (e) {
    print('Unhandled $e');
  }
  try {
    (await catchExceptionAsync()).fold((e) => print('Error: $e'), print);
  } catch (e) {
    print('Unhandled $e');
  }

  getStream().listen(print);
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoc081098/dart_either/issues
