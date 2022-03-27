import 'package:dart_either/dart_either.dart';

Either<Object, String> catchObject() {
  return Either.catchError(
    (e, s) => e,
    () => throw Exception('Demo exception'),
  );
}

Either<Exception, String> catchException() {
  return Either.catchError(
    (e, s) => e is Exception ? e : throw e,
    () => throw 'Error string',
  );
}

Future<Either<Object, String>> catchObjectAsync() {
  return Either.catchFutureError(
    (e, s) => e,
    () async {
      await Future<void>.delayed(const Duration(seconds: 1));
      throw Exception('Demo exception');
    },
  );
}

Future<Either<Exception, String>> catchExceptionAsync() {
  return Either.catchFutureError(
    (e, s) => e is Exception ? e : throw e,
    () async {
      await Future<void>.delayed(const Duration(seconds: 1));
      throw 'Error string';
    },
  );
}

Stream<Either<Object, int>> getStream() {
  return Stream.fromIterable([1, 2, 3, 4])
      .map((v) => v == 3 ? throw Exception('Demo exception') : v)
      .asEitherStream((e, s) => e);
}

Future<Either<Object, int>> monadComprehensions() {
  return Either.bindingFuture<Object, int>((e) async {
    final v1 = Either.right(999).bind(e);
    print('after v1 $v1');

    final v2 = Either.catchError((e, s) => e, () => 99).bind(e);
    print('after v2 $v2');

    final v3 = await Either.catchFutureError<Object, int>(
      (e, s) => e,
      () async => throw Exception('Demo exception'),
    ).bind(e);
    print('after v3 $v3');

    return v1 + v2 + v3;
  });
}

void main() async {
  (await monadComprehensions()).fold(
    ifLeft: (e) => print('Error: $e'),
    ifRight: print,
  );

  catchObject().fold(
    ifLeft: (e) => print('Error: $e'),
    ifRight: print,
  );
  (await catchObjectAsync()).fold(
    ifLeft: (e) => print('Error: $e'),
    ifRight: print,
  );

  try {
    catchException().fold(
      ifLeft: (e) => print('Error: $e'),
      ifRight: print,
    );
  } catch (e) {
    print('Unhandled $e');
  }
  try {
    (await catchExceptionAsync()).fold(
      ifLeft: (e) => print('Error: $e'),
      ifRight: print,
    );
  } catch (e) {
    print('Unhandled $e');
  }

  getStream().listen(print);
}
