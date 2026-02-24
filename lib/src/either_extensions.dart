
import 'dart_either.dart';

/// Provide [toFuture] extension on [Either].
extension AsFutureEitherExtension<L extends Object, R> on Either<L, R> {
  /// Convert this [Either] to a [Future].
  /// If [this] is [Right], the Future will complete with [Right.value] as its value.
  /// Otherwise, the result Future will complete with [Left.value] as its error.
  Future<R> toFuture() => fold(
        ifLeft: (e) => Future.error(e),
        ifRight: (v) => Future.value(v),
      );
}

/// Provide [getOrThrow] extension on [Either].
extension GetOrThrowEitherExtension<L extends Object, R> on Either<L, R> {
  /// Returns the [Right.value] if this [Either] is [Right], otherwise throws the [Left.value].
  /// This is functionally equivalent to `getOrHandle((value) => throw value)`.
  R getOrThrow() => getOrHandle((value) => throw value);
}
