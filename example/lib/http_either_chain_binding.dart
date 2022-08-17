import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart_ext/rxdart_ext.dart';
import 'package:tuple/tuple.dart';

typedef UserAndPosts = Tuple2<User, BuiltList<Post>>;

AsyncError toAsyncError(Object e, StackTrace s) => AsyncError(e, s);

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

  static Either<AsyncError, User> fromJsonAsEither(dynamic json) =>
      Either.catchError(
          toAsyncError, () => User.fromJson(json as Map<String, dynamic>));

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

  static Either<AsyncError, Post> fromJsonAsEither(dynamic json) =>
      Either.catchError(
          toAsyncError, () => Post.fromJson(json as Map<String, dynamic>));

  @override
  String toString() => 'Post{id: $id, userId: $userId, title: $title}';
}

Either<AsyncError, BuiltList<User>> toUsers(dynamic list) =>
    Either.traverse<AsyncError, User, dynamic>(
      list as List,
      User.fromJsonAsEither,
    );

Either<AsyncError, BuiltList<Post>> toPosts(dynamic list) =>
    Either.traverse<AsyncError, Post, dynamic>(
      list as List,
      Post.fromJsonAsEither,
    );

//-------------------------------------HTTP-------------------------------------

Future<Either<AsyncError, dynamic>> httpGetAsEither(String uriString) =>
    Either.futureBinding<AsyncError, dynamic>((e) async {
      final uri =
          Either.catchError(toAsyncError, () => Uri.parse(uriString)).bind(e);

      final response = await Either.catchFutureError(
        toAsyncError,
        () async {
          await delay(500);
          return http.get(uri);
        },
      ).bind(e);

      e.ensure(
        response.statusCode >= 200 && response.statusCode < 300,
        () => AsyncError(
          HttpException(
            'statusCode=${response.statusCode}, body=${response.body}',
            uri: response.request?.url,
          ),
          StackTrace.current,
        ),
      );

      return Either<AsyncError, dynamic>.catchError(
          toAsyncError, () => jsonDecode(response.body)).bind(e);
    });

//------------------------------------EXAMPLE-----------------------------------

void main() async {
  Future<Either<AsyncError, BuiltList<UserAndPosts>>> getPosts(
    BuiltList<User> users,
  ) =>
      Either.parTraverseN(
        users,
        (User user) => () {
          print('Get posts for $user...');

          return Either.futureBinding((e) async {
            final dynamic list = await httpGetAsEither(
                    'https://jsonplaceholder.typicode.com/posts?userId=${user.id}')
                .bind(e);

            final posts = toPosts(list).bind(e);

            return Tuple2(user, posts);
          });
        },
        3,
      );

  final result =
      await Either.futureBinding<AsyncError, BuiltList<UserAndPosts>>(
          (e) async {
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
