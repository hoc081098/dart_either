import '../dart_either.dart';
import '../internal.dart';

/// Adds [toFuture] to [Either].
extension AsFutureEitherExtension<L extends Object, R> on Either<L, R> {
  /// Converts this [Either] to a [Future].
  ///
  /// If `this` is [Right], the future completes with [Right.value] as its
  /// value. Otherwise, the future completes with [Left.value] as its error.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final int value = await Right<StateError, int>(12).toFuture();
  /// // value: 12
  ///
  /// final Future<int> failed =
  ///     Left<StateError, int>(StateError('missing')).toFuture();
  /// await failed; // Completes with StateError('missing').
  /// ```
  @covarianceSafe
  Future<R> toFuture() =>
      fold(ifLeft: Future<R>.error, ifRight: Future<R>.value);
}
