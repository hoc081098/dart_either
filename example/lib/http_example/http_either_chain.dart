import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart_ext/rxdart_ext.dart';

import 'shared_model.dart';

// ---------------------------------------------------------------------------
// 1) HTTP helper (flatMap chain style)
// ---------------------------------------------------------------------------

/// Get response from Uri as either using flatMap.
Future<Either<AppError, dynamic>> httpGetAsEither(String uriString) {
  Either<AppError, dynamic> toJson(http.Response response) {
    final int statusCode = response.statusCode;
    final String body = response.body;

    return statusCode >= 200 && statusCode < 300
        ? Either<AppError, dynamic>.tryCatch(
            action: () => jsonDecode(body),
            errorMapper: toAppError('jsonDecode: body=$body'),
          )
        : Either<AppError, dynamic>.left(
            AppError(
              HttpException(
                'statusCode=$statusCode, body=$body',
                uri: response.request?.url,
              ),
              StackTrace.current,
              'statusCode: $statusCode',
            ),
          );
  }

  Future<Either<AppError, http.Response>> httpGet(Uri uri) =>
      Either.tryCatchAsync(
        action: () async {
          await delay(500);
          return http.get(uri);
        },
        errorMapper: toAppError('http.get($uri)'),
      );

  final Future<Either<AppError, Uri>> uri = Future.value(
    Either.tryCatch(
      action: () => Uri.parse(uriString),
      errorMapper: toAppError('Parse $uriString'),
    ),
  );

  return uri.thenFlatMapEither(httpGet).thenFlatMapEither(toJson);
}

// ---------------------------------------------------------------------------
// 2) Demo flow: users + posts
// ---------------------------------------------------------------------------

void main() async {
  Future<Either<AppError, BuiltList<UserAndPosts>>> getPosts(
    BuiltList<User> users,
  ) =>
      Either.parTraverseN(
        values: users,
        mapper: (User user) => () {
          print('--> Get posts for $user...');

          return httpGetAsEither(
                  'https://jsonplaceholder.typicode.com/posts?userId=${user.id}')
              .thenFlatMapEither(toPosts)
              .thenMapEither((posts) => (user: user, posts: posts));
        },
        maxConcurrent: 3,
      );

  await httpGetAsEither('https://jsonplaceholder.typicode.com/users')
      .thenFlatMapEither(toUsers)
      .thenFlatMapEither(getPosts)
      .then(handleResult);
}
