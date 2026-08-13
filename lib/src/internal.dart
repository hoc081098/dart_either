import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

/// Marks an `Either` operation as safe for covariantly widened type arguments.
///
/// Apply this only after the operation has passed the proof or regression-test
/// requirements in `docs/either-variance-safety.md`.
@internal
const Object covarianceSafe = _CovarianceSafe();

@Target({TargetKind.method})
final class _CovarianceSafe {
  const _CovarianceSafe();
}

/// Returns [t] unchanged.
@internal
T identity<T>(T t) => t;
