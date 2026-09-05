import '../dart_either.dart';
import '../internal.dart';

/// Adds [merge] to [Either] values whose sides have the same type.
extension MergeEitherExtension<T> on Either<T, T> {
  /// Returns the value from [Left] or [Right].
  ///
  /// ### Example
  ///
  /// ```dart
  /// final int fromRight = Right<int, int>(12).merge(); // 12
  /// final int fromLeft = Left<int, int>(12).merge();   // 12
  /// ```
  @covarianceSafe
  T merge() => fold(ifLeft: identity, ifRight: identity);
}
