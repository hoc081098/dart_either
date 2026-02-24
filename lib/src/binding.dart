
import 'package:meta/meta.dart';

import 'dart_either.dart';
import 'extensions.dart';

/// Provide [ensure] extension on [EitherEffect].
extension EnsureEitherEffectExtension<L> on EitherEffect<L> {
  /// Ensure check if the [value] is `true`,
  /// and if it is it allows the `Either.binding(...)` to continue.
  /// In case it is `false`, then it short-circuits the binding and returns
  /// the provided value by [orLeft] inside a [Left].
  ///
  /// See [Either.binding] and [Either.futureBinding].
  ///
  /// ### Example
  /// ```dart
  /// final res = Either<String, int>.binding((e) {
  ///   e.ensure(true, () => '');
  ///   print('ensure(true) passes');
  ///   e.ensure(false, () => 'failed');
  ///   return 1;
  /// });
  /// // print: 'ensure(true) passes'
  /// // res: Left('failed')
  /// ```
  @monadComprehensions
  void ensure(bool value, L Function() orLeft) =>
      value ? null : bind(orLeft().left());
}

/// Provide [ensureNotNull] extension on [EitherEffect].
extension EnsureNotNullEitherEffectExtension<L> on EitherEffect<L> {
  /// Ensures that [value] is not null.
  /// When the value is not null, then it will be returned as non null and the check value is now smart-checked to non-null.
  /// Otherwise, if the [value] is null then the `Either.binding(...)` will short-circuit with [orLeft] inside of [Left].
  ///
  /// See [Either.binding] and [Either.futureBinding].
  ///
  /// ### Example
  /// ```dart
  /// final res = Either<String, int>.binding((e) {
  ///   int? x = 1;
  ///   e.ensureNotNull(x, () => 'passes');
  ///   print(x);
  ///
  ///   x = null;
  ///   e.ensureNotNull(x, () => 'failed');
  ///   print(x);
  ///
  ///   return 1;
  /// });
  /// // println: '1'
  /// // res: Left('failed')
  /// ```
  @useResult
  @monadComprehensions
  R ensureNotNull<R extends Object>(R? value, L Function() orLeft) =>
      value ?? bind(orLeft().left());
}

/// Provide [bindFuture] extension on [EitherEffect].
extension BindFutureEitherEffectExtension<L> on EitherEffect<L> {
  /// Attempt to get right value of [eitherFuture].
  /// Or return a [Future] that completes with a [ControlError].
  /// This is a shorthand for `eitherFuture.then(bind)`.
  ///
  /// See [Either.futureBinding].
  @monadComprehensions
  Future<R> bindFuture<R>(Future<Either<L, R>> eitherFuture) =>
      eitherFuture.then(bind);
}

/// Provide [bind] extension on an [Either].
extension BindEitherExtension<L, R> on Either<L, R> {
  /// Attempt to get right value of [this].
  /// Or throws a [ControlError].
  ///
  /// See [Either.binding] and [Either.futureBinding].
  @monadComprehensions
  R bind(EitherEffect<L> effect) => effect.bind(this);
}

/// Provide [bind] extension on a [Future] of [Either].
extension BindEitherFutureExtension<L, R> on Future<Either<L, R>> {
  /// Attempt to get right value of [this].
  /// Or return a [Future] that completes with a [ControlError].
  ///
  /// See [Either.futureBinding].
  @monadComprehensions
  Future<R> bind(EitherEffect<L> effect) => effect.bindFuture(this);
}
