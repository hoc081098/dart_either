import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart_ext/rxdart_ext.dart';

import 'shared_model.dart';

// ---------------------------------------------------------------------------
// 1) HTTP helper (futureBinding style)
// ---------------------------------------------------------------------------

/// Gets a response using direct-style asynchronous binding.
Future<Either<AppError, dynamic>> httpGetAsEither(String uriString) =>
    Either.futureBinding((effect) async {
      // A synchronous Either binds immediately. Left exits this scope.
      final Uri uri = Either.tryCatch(
        action: () => Uri.parse(uriString),
        errorMapper: toAppError('Parse $uriString'),
      ).bind(effect);

      // A Future<Either> must be awaited before its Right can be used.
      // tryCatchAsync turns non-fatal Future errors into AppError values.
      final http.Response response = await Either.tryCatchAsync(
        action: () async {
          await delay(500);
          return http.get(uri);
        },
        errorMapper: toAppError('http.get($uri)'),
      ).bind(effect);

      final int statusCode = response.statusCode;
      final String body = response.body;

      // Guards participate in the same short-circuiting scope.
      effect.ensure(
        statusCode >= 200 && statusCode < 300,
        () => AppError(
          HttpException(
            'statusCode=$statusCode, body=$body',
            uri: response.request?.url,
          ),
          StackTrace.current,
          'statusCode: $statusCode',
        ),
      );

      // The final bound Right becomes the successful value of futureBinding.
      return Either.tryCatch(
        action: () => jsonDecode(body),
        errorMapper: toAppError('jsonDecode: $body'),
      ).bind(effect);
    });

// ---------------------------------------------------------------------------
// 2) Demo flow: users + posts
// ---------------------------------------------------------------------------

void main() async {
  Future<Either<AppError, BuiltList<UserAndPosts>>> getPosts(
    BuiltList<User> users,
  ) =>
      Either.parTraverseN(
        values: users,
        mapper: (User user) => () => Either.futureBinding((effect) async {
              print('--> Get posts for $user...');

              // Get posts for user
              final dynamic list = await httpGetAsEither(
                      'https://jsonplaceholder.typicode.com/posts?userId=${user.id}')
                  .bind(effect);

              // Convert to post models
              final BuiltList<Post> posts = toPosts(list).bind(effect);

              // Return user and posts
              return (user: user, posts: posts);
            }),
        maxConcurrent: 3,
      );

  final Either<AppError, BuiltList<UserAndPosts>> result =
      await Either.futureBinding<AppError, BuiltList<UserAndPosts>>(
    (effect) async {
      // Each await + bind reads like ordinary async code. Any Left skips the
      // remaining statements and becomes the result of this outer scope.
      final dynamic list =
          await httpGetAsEither('https://jsonplaceholder.typicode.com/users')
              .bind(effect);

      // Synchronous Either values use the same effect without await.
      final BuiltList<User> users = toUsers(list).bind(effect);

      // Get posts for each user
      return await getPosts(users).bind(effect);
    },
  );

  handleResult(result);
}
