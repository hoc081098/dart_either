import '../dart_either.dart';
import '../internal.dart';

/// Provide [merge] extension when both sides have the same type.
extension MergeEitherExtension<T> on Either<T, T> {
  /// Returns the value from [Left] or [Right].
  ///
  /// ### Example
  /// ```dart
  /// Right<int, int>(12).merge(); // Result: 12
  /// Left<int, int>(12).merge();  // Result: 12
  /// ```
  @covarianceSafe
  T merge() => fold(ifLeft: identity, ifRight: identity);
}
