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
