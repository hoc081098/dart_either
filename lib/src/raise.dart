import 'dart:async';

import '../dart_either.dart';

/// TODO
typedef Raise<E> = _RaiseScope<Never Function(E)>;

extension RaiseExtension<E> on Raise<E> {
  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Never call(E value) => _raise(value);

  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Never raise(E value) => _raise(value);
}

final class RaiseError extends Error {
  final _RaiseScope<dynamic> _raise;

  /// The value was raised.
  final Object? _raised;

  RaiseError._(this._raise, this._raised);

  @override
  String toString() => 'RaiseError($_raise, $_raised)';
}

enum _RaisePhase {
  active,
  raised,
  closed,
}

final class _RaiseScope<AcceptsLeft extends Function> {
  var _phase = _RaisePhase.active;

  _RaiseScope._();

  void _close() {
    _phase = _RaisePhase.closed;
  }

  void _throwIfRaised() {
    if (_phase == _RaisePhase.raised) {
      throw StateError('Binding short-circuit was intercepted.');
    }
  }

  @pragma('vm:always-consider-inlining')
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _ensureActive() {
    if (_phase != _RaisePhase.active) {
      throw StateError('EitherEffect was used outside its binding scope.');
    }
  }

  Never _raise<L>(L value) {
    _ensureActive();

    _phase = _RaisePhase.raised;
    throw RaiseError._(this, value);
  }
}

Res fold<E, A, Res>({
  required A Function(Raise<E> raise) block,
  required Res Function(A value) transform,
  required Res Function(E error) recover,
}) {
  final Raise<E> raise = _RaiseScope<Never Function(E)>._();

  try {
    final res = block(raise);

    raise._throwIfRaised();
    raise._close();

    return transform(res);
  } on RaiseError catch (e) {
    raise._close();

    if (identical(raise, e._raise)) {
      return recover(e._raised as E);
    } else {
      rethrow;
    }
  } catch (e) {
    raise._close();

    rethrow;
  }
}

Future<Res> asyncFold<E, A, Res>({
  required Future<A> Function(Raise<E> raise) block,
  required FutureOr<Res> Function(A value) transform,
  required FutureOr<Res> Function(E error) recover,
}) async {
  final Raise<E> raise = _RaiseScope<Never Function(E)>._();

  try {
    final res = await Future.sync(() => block(raise));

    raise._throwIfRaised();
    raise._close();

    return transform(res);
  } on RaiseError catch (e) {
    raise._close();

    if (identical(raise, e._raise)) {
      return  recover(e._raised as E);
    } else {
      rethrow;
    }
  } catch (e) {
    raise._close();

    rethrow;
  }
}


Either<L, R> either<L, R>(R Function(Raise<L> raise) block) =>
    fold<L, R, Either<L, R>>(
      block: block,
      transform: Either<L, R>.right,
      recover: Either<L, R>.left,
    );

int parsePositiveIntSafe(String s, Raise<String> raise) {
  final value = int.tryParse(s);
  return switch (value) {
    null => raise('Invalid integer: $s'),
    <= 0 => raise('Not a positive integer: $s'),
    _ => value,
  };
}

Future<int> parsePositiveIntSafeAsync(String s, Raise<String> raise) async {
  final value = int.tryParse(s);

  await Future<void>.delayed(const Duration(seconds: 1));

  return switch (value) {
    null => raise('Invalid integer: $s'),
    <= 0 => raise('Not a positive integer: $s'),
    _ => value,
  };
}

void main() async {
  fold<String, int, void>(
    block: (raise) => parsePositiveIntSafe('invalid', raise),
    transform: (v) => print('Success: $v'),
    recover: (e) => print('Failure: $e'),
  );

  fold<String, int, void>(
    block: (raise) => parsePositiveIntSafe('-2', raise),
    transform: (v) => print('Success: $v'),
    recover: (e) => print('Failure: $e'),
  );

  fold<String, int, void>(
    block: (raise) => parsePositiveIntSafe('123', raise),
    transform: (v) => print('Success: $v'),
    recover: (e) => print('Failure: $e'),
  );

  [
    either<String, int>((raise) => parsePositiveIntSafe('invalid', raise)),
    either<String, int>((raise) => parsePositiveIntSafe('-2', raise)),
    either<String, int>((raise) => parsePositiveIntSafe('123', raise)),
  ].forEach(print);

  await asyncFold<String, int, void>(
    block: (raise) => parsePositiveIntSafeAsync('123', raise),
    transform: (v) => print('Success: $v'),
    recover: (e) => print('Failure: $e'),
  );
}
