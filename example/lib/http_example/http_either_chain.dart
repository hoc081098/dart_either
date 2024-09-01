import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart_ext/rxdart_ext.dart';

import 'shared_model.dart';

//-------------------------------------HTTP-------------------------------------

/// Get response from Uri as either using flatMap.
Future<Either<AppError, dynamic>> httpGetAsEither(String uriString) {
  Either<AppError, dynamic> toJson(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    return statusCode >= 200 && statusCode < 300
        ? Either<AppError, dynamic>.catchError(
            toAppError('jsonDecode: body=$body'),
            () => jsonDecode(body),
          )
        : AppError(
            HttpException(
              'statusCode=$statusCode, body=$body',
              uri: response.request?.url,
            ),
            StackTrace.current,
            'statusCode: $statusCode',
          ).left();
  }

  Future<Either<AppError, http.Response>> httpGet(Uri uri) =>
      Either.catchFutureError(
        toAppError('http.get($uri)'),
        () async {
          await delay(500);
          return http.get(uri);
        },
      );

  final uri = Future.value(
    Either.catchError(
      toAppError('Parse $uriString'),
      () => Uri.parse(uriString),
    ),
  );

  return uri.thenFlatMapEither(httpGet).thenFlatMapEither(toJson);
}

//------------------------------------EXAMPLE-----------------------------------

void main() async {
  Future<Either<AppError, BuiltList<UserAndPosts>>> getPosts(
    BuiltList<User> users,
  ) =>
      Either.parTraverseN(
        users,
        (User user) => () {
          print('--> Get posts for $user...');

          return httpGetAsEither(
                  'https://jsonplaceholder.typicode.com/posts?userId=${user.id}')
              .thenFlatMapEither(toPosts)
              .thenMapEither((posts) => (user: user, posts: posts));
        },
        3,
      );

  await httpGetAsEither('https://jsonplaceholder.typicode.com/users')
      .thenFlatMapEither(toUsers)
      .thenFlatMapEither(getPosts)
      .then(handleResult);
}
