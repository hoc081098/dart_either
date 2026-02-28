import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart_ext/rxdart_ext.dart';

import 'shared_model.dart';

//-------------------------------------HTTP-------------------------------------

/// Get response from Uri as either using Monad Comprehension
Future<Either<AppError, dynamic>> httpGetAsEither(String uriString) =>
    Either.futureBinding((e) async {
      // Create Uri
      final uri = Either.catchError(
        toAppError('Parse $uriString'),
        () => Uri.parse(uriString),
      ).bind(e);

      // Get response
      final response = await Either.catchFutureError(
        toAppError('http.get($uri)'),
        () async {
          await delay(500);
          return http.get(uri);
        },
      ).bind(e);

      final statusCode = response.statusCode;
      final body = response.body;

      // Check status code
      e.ensure(
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

      // Decode body to json
      return Either.catchError(
        toAppError('jsonDecode: $body'),
        () => jsonDecode(body),
      ).bind(e);
    });

//------------------------------------EXAMPLE-----------------------------------

void main() async {
  Future<Either<AppError, BuiltList<UserAndPosts>>> getPosts(
    BuiltList<User> users,
  ) =>
      Either.parTraverseN(
        values: users,
        mapper: (User user) => () => Either.futureBinding((e) async {
              print('--> Get posts for $user...');

              // Get posts for user
              final list = await httpGetAsEither(
                      'https://jsonplaceholder.typicode.com/posts?userId=${user.id}')
                  .bind(e);

              // Convert to post models
              final posts = toPosts(list).bind(e);

              // Return user and posts
              return (user: user, posts: posts);
            }),
        maxConcurrent: 3,
      );

  final result = await Either.futureBinding<AppError, BuiltList<UserAndPosts>>(
    (e) async {
      // Get user list
      final list =
          await httpGetAsEither('https://jsonplaceholder.typicode.com/users')
              .bind(e);

      // Convert to user models
      final users = toUsers(list).bind(e);

      // Get posts for each user
      return await getPosts(users).bind(e);
    },
  );

  handleResult(result);
}
