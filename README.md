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

### Import

```dart
import 'package:dart_either/dart_either.dart';
```

### Catch synchronous errors

```dart
Either<Object, String> catchObject() {
  return Either.catchError(
    (e, s) => e,
    () => throw Exception('Test'),
  );
}

Either<Exception, String> catchException() {
  return Either.catchError(
    (e, s) => e is Exception ? e : throw e,
    () => throw 'A string',
  );
}
```

### Catch asynchronous errors (Future and Stream)

```dart
Future<Either<Object, String>> catchObjectAsync() {
  return Either.catchFutureError(
    (e, s) => e,
    () async {
      await Future<void>.delayed(const Duration(seconds: 1));
      throw Exception('Test 2');
    },
  );
}

Future<Either<Exception, String>> catchExceptionAsync() {
  return Either.catchFutureError(
    (e, s) => e is Exception ? e : throw e,
    () async {
      await Future<void>.delayed(const Duration(seconds: 1));
      throw 'A string';
    },
  );
}

Stream<Either<Object, int>> getStream() {
  return Stream.fromIterable([1, 2, 3, 4])
      .map((v) => v == 3 ? throw Exception('Error...') : v)
      .asEitherStream((e, s) => e);
}
```

### Monad comprehensions (binding)

```dart
Future<Either<Object, int>> monadComprehensions() {
  return Either.bindingFuture<Object, int>((e) async {
    final v1 = e << Right(999);
    print('after v1 $v1');

    final v2 = e << Either.catchError((e, s) => e, () => 99);
    print('after v2 $v2');

    final v3 = await e.bindFuture(Either.catchFutureError(
      (e, s) => e,
      () async => throw Exception('Hihi'),
    ));
    print('after v3 $v3');

    return v1 + v2 + v3;
  });
}
```

### Main

```dart
void main() async {
  (await monadComprehensions()).fold((e) => print('Error: $e'), print);

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
