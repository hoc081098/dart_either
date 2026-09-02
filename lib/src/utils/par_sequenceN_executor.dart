part of '../dart_either.dart';

@internal
class ParSequenceNExecutor<L, R> {
  final Iterable<Future<Either<L, R>> Function()> functions;
  final int? maxConcurrent;

  ParSequenceNExecutor(this.functions, this.maxConcurrent);

  Future<Either<L, BuiltList<R>>> run() {
    final mx = maxConcurrent;

    ControlError<L>? leftRaised;

    final futureFunctions = functions.toList(growable: false);
    final semaphore = mx != null ? Semaphore(mx) : null;
    final token = _Token();

    Future<R> Function() run(Future<Either<L, R>> Function() f) {
      return () {
        // Check before execution of f.
        if (leftRaised != null) {
          throw leftRaised!;
        }
        return Future.sync(f).then(
          (e) {
            // Check after then the f is completed.
            if (leftRaised != null) {
              throw leftRaised!;
            }

            return e.fold(
              ifLeft: (l) => throw ControlError<L>._(l, token),
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
      (e, s) {
        leftRaised = e;
        return Left(e._value);
      },
      test: (e) => identical(e._token, token),
    );
  }
}
