import 'dart_either.dart';

/// Provide [toFuture] extension on [Either].
extension AsFutureEitherExtension<L extends Object, R> on Either<L, R> {
  /// Convert this [Either] to a [Future].
  /// If [this] is [Right], the Future will complete with [Right.value].
  /// If [this] is [Left], the Future will complete with [Left.value] as an error.
  Future<R> toFuture() => fold(
        ifLeft: (e) => Future.error(e),
        ifRight: (v) => Future.value(v),
      );
}

/// Provide [toEitherStream] extension on [Stream].
extension ToEitherStreamExtension<R> on Stream<R> {
  /// TODO(catchStreamError)
  Stream<Either<L, R>> toEitherStream<L>(ErrorMapper<L> errorMapper) =>
      Either.catchStreamError<L, R>(errorMapper, this);
}

/// Provide [left] and [right] extensions on any types.
extension ToEitherObjectExtension<T> on T {
  /// Return a [Left] that contains [this] value.
  /// Can cast returned result to any `Either<T, ...>` type.
  ///
  /// For example:
  /// ```
  /// Either<int, Never> e1 = 1.left();
  /// Either<int, String> e2 = 1.left();
  /// Either<int, dynamic> e3 = 1.left();
  /// ``
  Either<T, R> left<R>() => Either<T, R>.left(this);

  /// Return a [Right] that contains [this] value.
  /// Can cast returned result to any `Either<..., T>` type.
  ///
  /// For example:
  /// ```
  /// Either<Never, int> e1 = 1.right();
  /// Either<String, int> e2 = 1.right();
  /// Either<dynamic, int> e3 = 1.right();
  /// ``
  Either<L, T> right<L>() => Either<L, T>.right(this);
}
