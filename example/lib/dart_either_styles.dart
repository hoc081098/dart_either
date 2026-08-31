import 'package:dart_either/dart_either.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

// ---------------------------------------------------------------------------
// 1) Domain model + fake APIs
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// 2) Imperative baseline (exceptions + nullable)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// 3) Either wrappers
// ---------------------------------------------------------------------------

Future<Either<String, User?>> findUserByIdEither(String id) =>
    Either.tryCatchAsync(
      action: () => findUserById(id),
      errorMapper: (e, s) => 'findUserById failed: $e, $s',
    );

Future<Either<String, List<Post>>> getPostsByUserEither(User user) =>
    Either.tryCatchAsync(
      action: () => getPostsByUser(user),
      errorMapper: (e, s) => 'getPostsByUser failed: $e, $s',
    );

Future<Either<String, void>> doSomethingWithPostsEither(
  User user,
  List<Post> posts,
) =>
    Either.tryCatchAsync(
      action: () => doSomethingWithPosts(user, posts),
      errorMapper: (e, s) => 'doSomethingWithPosts failed: $e, $s',
    );

// ---------------------------------------------------------------------------
// 4) Composition style A: flatMap chain
// ---------------------------------------------------------------------------

Future<Either<String, void>> eitherFlatMapCode() =>
    findUserByIdEither('user_id').thenFlatMapEither((user) {
      if (user == null) {
        return Either<String, List<Post>>.left('User is null');
      }
      return getPostsByUserEither(user).thenFlatMapEither(
          (posts) => doSomethingWithPostsEither(user, posts));
    });

// ---------------------------------------------------------------------------
// 5) Composition style B: futureBinding (monad comprehensions)
// ---------------------------------------------------------------------------

Future<Either<String, void>> eitherBindingCode() =>
    Either.futureBinding((effect) async {
      final User? nullableUser =
          await findUserByIdEither('user_id').bind(effect);
      final User user = effect.ensureNotNull(
        nullableUser,
        () => 'User is null',
      );
      final List<Post> posts = await getPostsByUserEither(user).bind(effect);
      await doSomethingWithPostsEither(user, posts).bind(effect);
    });

// ---------------------------------------------------------------------------
// 6) Demo
// ---------------------------------------------------------------------------

void main() async {
  await imperativeCode();
  print(await eitherFlatMapCode());
  print(await eitherBindingCode());
}
