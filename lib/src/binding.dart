import 'package:meta/meta.dart';

import 'dart_either.dart';
import 'extensions.dart';

// -----------------------------------------------------------------------------
// Extensions on EitherEffect
// -----------------------------------------------------------------------------

/// Provides [ensure] on a scope-bound [EitherEffect].
extension EnsureEitherEffectExtension<L> on EitherEffect<L> {
  /// Continues the binding scope when [value] is `true`.
  ///
  /// When [value] is `false`, evaluates [orLeft] and short-circuits the scope
  /// with its result in a [Left].
  ///
  /// See [Either.binding] and [Either.futureBinding].
  ///
  /// ### Example
  /// ```dart
  /// final result = Either<String, int>.binding((effect) {
  ///   effect.ensure(true, () => 'unused');
  ///   print('ensure(true) passes');
  ///   effect.ensure(false, () => 'failed');
  ///   return 1;
  /// });
  /// // print: 'ensure(true) passes'
  /// // result: Left('failed')
  /// ```
  @monadComprehensions
  void ensure(bool value, L Function() orLeft) =>
      value ? null : bind<Never>(orLeft().left<Never>());
}

/// Provides [ensureNotNull] on a scope-bound [EitherEffect].
extension EnsureNotNullEitherEffectExtension<L> on EitherEffect<L> {
  /// Returns [value] as a non-nullable [R] when it is not `null`.
  ///
  /// When [value] is `null`, evaluates [orLeft] and short-circuits the binding
  /// scope with its result in a [Left]. Assign the returned value; Dart does
  /// not promote the original variable across this method call.
  ///
  /// See [Either.binding] and [Either.futureBinding].
  ///
  /// ### Example
  /// ```dart
  /// final result = Either<String, int>.binding((effect) {
  ///   final int? nullableValue = 1;
  ///   final value = effect.ensureNotNull(nullableValue, () => 'missing');
  ///   return value + 1;
  /// });
  /// // result: Right(2)
  /// ```
  @useResult
  @monadComprehensions
  R ensureNotNull<R extends Object>(R? value, L Function() orLeft) =>
      value ?? bind<R>(orLeft().left<R>());
}

/// Provides [bindFuture] on a scope-bound [EitherEffect].
extension BindFutureEitherEffectExtension<L> on EitherEffect<L> {
  /// Returns the right value produced by [eitherFuture].
  ///
  /// A produced [Left] short-circuits the surrounding [Either.futureBinding]
  /// scope. An error emitted by [eitherFuture] propagates unchanged.
  /// This is a shorthand for `eitherFuture.then(bind)`.
  ///
  /// See [Either.futureBinding].
  ///
  /// ### Example
  /// ```dart
  /// final result = await Either.futureBinding<String, int>((effect) async {
  ///   final int userId = await effect.bindFuture(
  ///     Future.value(Either<String, int>.right(1)),
  ///   );
  ///   final int postCount = await effect.bindFuture(
  ///     Future.value(Either<String, int>.right(userId + 2)),
  ///   );
  ///   return postCount;
  /// }); // Right(3)
  /// ```
  @monadComprehensions
  Future<R> bindFuture<R>(Future<Either<L, R>> eitherFuture) =>
      eitherFuture.then(bind);
}

// -----------------------------------------------------------------------------
// Binding syntax extensions: receive an EitherEffect
// -----------------------------------------------------------------------------

/// Provides binding syntax on an [Either].
extension BindEitherExtension<L, R> on Either<L, R> {
  /// Returns this [Either]'s right value through [effect].
  ///
  /// A [Left] short-circuits the [Either.binding] or [Either.futureBinding]
  /// scope that owns [effect].
  ///
  /// See [Either.binding] and [Either.futureBinding].
  ///
  /// ### Example
  /// ```dart
  /// final result = Either<String, int>.binding((effect) {
  ///   return Either<String, int>.right(1).bind(effect);
  /// }); // Right(1)
  /// ```
  @monadComprehensions
  R bind(EitherEffect<L> effect) => effect.bind<R>(this);
}

/// Provides binding syntax on a [Future] of [Either].
extension BindEitherFutureExtension<L, R> on Future<Either<L, R>> {
  /// Returns the right value produced by this future through [effect].
  ///
  /// A produced [Left] short-circuits the [Either.futureBinding] scope that
  /// owns [effect]. An error emitted by this future propagates unchanged.
  ///
  /// See [Either.futureBinding].
  ///
  /// ### Example
  /// ```dart
  /// final result = await Either.futureBinding<String, int>((effect) async {
  ///   return Future.value(Either<String, int>.right(1)).bind(effect);
  /// }); // Right(1)
  /// ```
  @monadComprehensions
  Future<R> bind(EitherEffect<L> effect) => then(effect.bind);
}
/// Provides binding syntax on a nullable value.
extension BindNullableValueExtension<R extends Object> on R? {
  /// Returns this value as non-nullable [R] through [effect].
  ///
  /// When this value is `null`, evaluates [orLeft] and short-circuits the
  /// [Either.binding] or [Either.futureBinding] scope that owns [effect]
  /// with the result in a [Left].
  ///
  /// See [Either.binding] and [Either.futureBinding].
  ///
  /// ### Example
  /// ```dart
  /// final result = Either<String, int>.binding((effect) {
  ///   final int? nullableValue = 1;
  ///   final int value = nullableValue.bind(effect, () => 'missing');
  ///   return value + 1;
  /// }); // Right(2)
  /// ```
  @monadComprehensions
  R bind<L>(EitherEffect<L> effect, L Function() orLeft) {
    final value = this;
    return value ?? effect.bind<R>(orLeft().left<R>());
  }
}