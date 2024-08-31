import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart_ext/rxdart_ext.dart';
import 'package:tuple/tuple.dart';

typedef UserAndPosts = Tuple2<User, BuiltList<Post>>;

class AppError {
  final Object error;
  final StackTrace stackTrace;
  final String message;

  AppError(this.error, this.stackTrace, this.message);

  @override
  String toString() =>
      'AppError {\n    error: $error, \n    stackTrace: $stackTrace, \n    message: $message\n}';
}

AppError Function(Object, StackTrace) toAppError(String message) =>
    (e, s) => AppError(e, s, message);

//------------------------------------MODELS------------------------------------

class User {
  final int id;
  final String name;
  final String username;

  User({
    required this.id,
    required this.name,
    required this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: json['name'] as String,
        username: json['username'] as String,
      );

  static Either<AppError, User> fromJsonAsEither(dynamic json) =>
      Either.catchError(toAppError('User.fromJsonAsEither: $json'),
          () => User.fromJson(json as Map<String, dynamic>));

  @override
  String toString() => 'User{id: $id, name: $name, username: $username}';
}

class Post {
  final int id;
  final int userId;
  final String title;

  Post({
    required this.id,
    required this.userId,
    required this.title,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        title: json['title'] as String,
        userId: json['userId'] as int,
      );

  static Either<AppError, Post> fromJsonAsEither(dynamic json) =>
      Either.catchError(toAppError('Post.fromJsonAsEither: $json'),
          () => Post.fromJson(json as Map<String, dynamic>));

  @override
  String toString() => 'Post{id: $id, userId: $userId, title: $title}';
}

Either<AppError, BuiltList<User>> toUsers(dynamic list) =>
    Either.traverse<AppError, User, dynamic>(
      list as List,
      User.fromJsonAsEither,
    );

Either<AppError, BuiltList<Post>> toPosts(dynamic list) =>
    Either.traverse<AppError, Post, dynamic>(
      list as List,
      Post.fromJsonAsEither,
    );

//-------------------------------------HTTP-------------------------------------

Future<Either<AppError, dynamic>> httpGetAsEither(String uriString) =>
    Either.futureBinding<AppError, dynamic>((e) async {
      final uri = Either.catchError(
          toAppError('Parse $uriString'), () => Uri.parse(uriString)).bind(e);

      final response = await Either.catchFutureError(
        toAppError('http.get($uri)'),
        () async {
          await delay(500);
          return http.get(uri);
        },
      ).bind(e);

      final statusCode = response.statusCode;
      final body = response.body;

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

      return Either<AppError, dynamic>.catchError(
          toAppError('jsonDecode: $body'), () => jsonDecode(body)).bind(e);
    });

//------------------------------------EXAMPLE-----------------------------------

void main() async {
  Future<Either<AppError, BuiltList<UserAndPosts>>> getPosts(
    BuiltList<User> users,
  ) =>
      Either.parTraverseN(
        users,
        (User user) => () => Either.futureBinding((e) async {
              print('Get posts for $user...');

              final dynamic list = await httpGetAsEither(
                      'https://jsonplaceholder.typicode.com/posts?userId=${user.id}')
                  .bind(e);

              final posts = toPosts(list).bind(e);

              return Tuple2(user, posts);
            }),
        3,
      );

  final result =
      await Either.futureBinding<AppError, BuiltList<UserAndPosts>>((e) async {
    final dynamic list =
        await httpGetAsEither('https://jsonplaceholder.typicode.com/users')
            .bind(e);

    final users = toUsers(list).bind(e);

    return await getPosts(users).bind(e);
  });

  result.fold(
    ifLeft: (e) => print('Error: $e'),
    ifRight: (items) => print('Success: ${items.length}'),
  );
}
