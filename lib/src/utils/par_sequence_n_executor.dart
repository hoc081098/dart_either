part of '../dart_either.dart';

final class _ParSequenceNExecutor<L, R> {
  final Iterable<Future<Either<L, R>> Function()> _functions;
  final int? _maxConcurrent;

  _ParSequenceNExecutor(this._functions, this._maxConcurrent);

  @pragma('vm:prefer-inline')
  static Never throwFailure(AsyncError failure) =>
      Error.throwWithStackTrace(failure.error, failure.stackTrace);

  Future<Either<L, BuiltList<R>>> run() {
    final mx = _maxConcurrent;

    final futureFunctions = _functions.toList(growable: false);
    final semaphore = mx != null ? Semaphore(mx) : null;
    final token = _Token();

    AsyncError? firstFailure;

    Future<R> Function() run(Future<Either<L, R>> Function() f) {
      return () {
        // Reject a queued function before invoking it.
        final observedFailure = firstFailure;
        if (observedFailure != null) {
          throwFailure(observedFailure);
        }

        return Future.sync(f).then(
          (e) {
            // Preserve the first failure observed while this function was running.
            final observedFailure = firstFailure;
            if (observedFailure != null) {
              throwFailure(observedFailure);
            }

            return e.fold(
              ifLeft: (l) => throw ControlError<L>._(l, token),
              ifRight: identity,
            );
          },
        ).onError<Object>((error, stackTrace) {
          final failure = firstFailure ??= AsyncError(error, stackTrace);
          throwFailure(failure);
        });
      };
    }

    Future<R> runWithPermit(Future<Either<L, R>> Function() f) {
      final action = run(f);
      return semaphore?.withPermit(action) ?? action();
    }

    return Future.wait(
      futureFunctions.map(runWithPermit),
      eagerError: true,
    )
        .then((values) => Either<L, BuiltList<R>>.right(values.build()))
        .onError<ControlError<L>>(
          (e, s) => Left(e._value),
          test: (e) => identical(e._token, token),
        );
  }
}
