import 'dart_either.dart';
import 'extensions.dart';

/// Provide [ensure] extension on [EitherEffect].
extension EnsureEitherEffectExtension<L, R> on EitherEffect<L, R> {
  /// Ensure check if the [value] is `true`,
  /// and if it is it allows the `Either.binding(...)` to continue.
  /// In case it is `false`, then it short-circuits the binding and returns
  /// the provided value by [orLeft] inside a [Left].
  ///
  /// ```dart
  ///   final res = Either<String, int>.binding((e) {
  ///     e.ensure(true, () => "");
  ///     print("ensure(true) passes");
  ///     e.ensure(false, () => "failed");
  ///     return 1;
  ///   });
  /// // print: "ensure(true) passes"
  /// // res: Either.Left("failed")
  /// ```
  @monadComprehensions
  void ensure(bool value, L Function() orLeft) =>
      value ? null : bind(orLeft().left());
}

/// Provide [ensureNotNull] extension on [EitherEffect].
extension EnsureNotNullEitherEffectExtension<L, R extends Object>
    on EitherEffect<L, R> {
  /// Ensures that [value] is not null.
  /// When the value is not null, then it will be returned as non null and the check value is now smart-checked to non-null.
  /// Otherwise, if the [value] is null then the `Either.binding(...)` will short-circuit with [orLeft] inside of [Left].
  ///
  /// ```dart
  ///   final res = Either<String, int>.binding((e) {
  ///     int? x = 1;
  ///     e.ensureNotNull(x, () => "passes");
  ///     print(x);
  ///     e.ensureNotNull(null, () => "failed");
  ///     return 1;
  ///   });
  ///   print(res);
  /// // println: "1"
  /// // res: Either.Left("failed")
  /// ```
  @monadComprehensions
  R ensureNotNull(R? value, L Function() orLeft) =>
      value ?? bind(orLeft().left());
}

/// Provide [bind] extension on an [Either].
extension BindEitherExtension<L, R> on Either<L, R> {
  /// Attempt to get right value of [this].
  /// Or throws a [ControlError].
  @monadComprehensions
  R bind(EitherEffect<L, R> effect) => effect.bind(this);
}

/// Provide [bind] extension on a [Future] of [Either].
extension BindEitherFutureExtension<L, R> on Future<Either<L, R>> {
  /// Attempt to get right value of [this].
  /// Or return a [Future] that completes with a [ControlError].
  @monadComprehensions
  Future<R> bind(EitherEffect<L, R> effect) => effect.bindFuture(this);
}
