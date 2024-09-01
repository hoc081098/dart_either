import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';

//-------------------------------------MODEL-------------------------------------

typedef UserAndPosts = ({User user, BuiltList<Post> posts});

class AppError {
  final Object error;
  final StackTrace stackTrace;
  final String message;

  AppError(this.error, this.stackTrace, this.message);

  @override
  String toString() =>
      'AppError {\n    error: $error, \n    stackTrace: $stackTrace, \n    message: $message\n}';
}

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

//-------------------------------------MAPPER-------------------------------------

AppError Function(Object, StackTrace) toAppError(String message) =>
    (e, s) => AppError(e, s, message);

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

void handleResult(Either<AppError, BuiltList<UserAndPosts>> result) =>
    result.fold(
      ifLeft: (e) => print('Error: $e'),
      ifRight: (items) {
        print('${'-' * 35} Success ${'-' * 35}');
        print('Success: ${items.length}');
        for (final item in items) {
          print('>>> User: ${item.user}');
          for (final post in item.posts) {
            print('        Post: $post');
          }
          print('-' * 80);
        }
      },
    );
