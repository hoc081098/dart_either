import 'package:dart_either/dart_either.dart';

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
