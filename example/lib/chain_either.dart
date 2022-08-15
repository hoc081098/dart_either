import 'package:dart_either/dart_either.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

//--------------------------------------API--------------------------------------

class User {
  final String uuid;

  User({required this.uuid});
}

class Post {
  final String id;
  final String title;
  final String userId;

  Post({
    required this.id,
    required this.title,
    required this.userId,
  });
}

Future<User?> findUserById(String id) async {
  await delay(100);
  return User(uuid: id);
}

Future<List<Post>> getPostsByUser(User user) async {
  await delay(100);
  return [
    Post(id: '1', title: 'Title 1', userId: user.uuid),
    Post(id: '2', title: 'Title 2', userId: user.uuid),
  ];
}

Future<void> doSomethingWithPosts(User user, List<Post> posts) => delay(100);

//----------------------------------IMPERATIVE----------------------------------

Future<void> imperativeCode() async {
  try {
    final User? user = await findUserById('user_id');
    if (user == null) {
      print('User is null');
      return;
    }

    final List<Post> posts = await getPostsByUser(user);
    await doSomethingWithPosts(user, posts);

    print('Success');
  } catch (e, s) {
    // Handle exceptions from any of the methods above
    print('Error: $e');
    print('Stacktrace: $s');
  }
}

//----------------------------------EITHER API----------------------------------

Future<Either<String, User?>> findUserByIdEither(String id) =>
    Either.catchFutureError(
      (e, s) => 'findUserById failed: $e, $s',
      () => findUserById(id),
    );

Future<Either<String, List<Post>>> getPostsByUserEither(User user) =>
    Either.catchFutureError(
      (e, s) => 'getPostsByUser failed: $e, $s',
      () => getPostsByUser(user),
    );

Future<Either<String, void>> doSomethingWithPostsEither(
  User user,
  List<Post> posts,
) =>
    Either.catchFutureError(
      (e, s) => 'doSomethingWithPosts failed: $e, $s',
      () => doSomethingWithPosts(user, posts),
    );

//--------------------------------EITHER FLATMAP--------------------------------

Future<Either<String, void>> eitherFlatMapCode() =>
    findUserByIdEither('user_id').thenFlatMap((user) {
      if (user == null) {
        return 'User is null'.left<List<Post>>();
      }
      return getPostsByUserEither(user)
          .thenFlatMap((posts) => doSomethingWithPostsEither(user, posts));
    });

//--------------------------------EITHER BINDING--------------------------------

Future<Either<String, void>> eitherBindingCode() =>
    Either.futureBinding((e) async {
      final nullableUser = await findUserByIdEither('user_id').bind(e);
      final user = e.ensureNotNull(nullableUser, () => 'User is null');
      final posts = await getPostsByUserEither(user).bind(e);
      await doSomethingWithPostsEither(user, posts).bind(e);
    });

void main() async {
  await imperativeCode();
  print(await eitherFlatMapCode());
  print(await eitherBindingCode());
}
