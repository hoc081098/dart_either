part of '../dart_either.dart';

final class _ParSequenceNExecutor<L, R> {
  final Iterable<Future<Either<L, R>> Function()> _functions;
  final int? _maxConcurrent;

  _ParSequenceNExecutor(this._functions, this._maxConcurrent);

  Future<Either<L, BuiltList<R>>> run() {
    final mx = _maxConcurrent;

    ControlError<L>? leftRaised;

    final futureFunctions = _functions.toList(growable: false);
    final semaphore = mx != null ? Semaphore(mx) : null;
    final token = _Token();

    Future<R> Function() run(Future<Either<L, R>> Function() f) {
      return () {
        // Reject a queued function before invoking it.
        if (leftRaised != null) {
          throw leftRaised!;
        }
        return Future.sync(f).then(
          (e) {
            // Preserve the first Left observed while this function was running.
            if (leftRaised != null) {
              throw leftRaised!;
            }

            return e.fold(
              ifLeft: (l) {
                final error = ControlError<L>._(l, token);
                leftRaised ??= error;
                throw leftRaised!;
              },
              ifRight: identity,
            );
          },
        );
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
