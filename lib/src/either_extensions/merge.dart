import '../dart_either.dart';
import '../internal.dart';

/// Adds [merge] to [Either].
extension MergeEitherExtension<T> on Either<T, T> {
  /// Returns [Left.value] or [Right.value] as their inferred common type.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final int fromRight = Right<int, int>(12).merge();         // 12
  /// final int fromLeft = Left<int, int>(12).merge();           // 12
  /// final Object widened = Left<String, int>('error').merge(); // 'error'
  /// ```
  @covarianceSafe
  T merge() => fold(ifLeft: identity, ifRight: identity);
}
