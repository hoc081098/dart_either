import 'dart:async';

import 'dart:collection';

import 'package:meta/meta.dart';

/// A counting semaphore for coroutines that logically maintains a number of available permits.
/// Each [acquire] takes a single permit or suspends until it is available.
/// Each [release] adds a permit, potentially releasing a suspended acquirer.
/// Semaphore is fair and maintains a FIFO order of acquirers.
///
/// Semaphores are mostly used to limit the number of coroutines that have an access to particular resource.
/// Semaphore with `permits = 1` is essentially a [Mutex].
///
@experimental
abstract class Semaphore {
  /// Creates new [Semaphore] instance.
  /// [permits] is the number of permits available in this semaphore.
  factory Semaphore(int permits) => _SemaphoreImpl(permits);

  /// Acquires a permit from this semaphore, suspending until one is available.
  /// All suspending acquirers are processed in first-in-first-out (FIFO) order.
  Future<void>? acquire();

  /// Releases a permit, returning it into this semaphore.
  /// Resumes the first suspending acquirer if there is one at the point of invocation.
  /// Throws [StateError] if the number of [release] invocations is greater
  /// than the number of preceding [acquire].
  void release();
}

class _SemaphoreImpl implements Semaphore {
  final int _permits;
  var _current = 0;
  final _signals = DoubleLinkedQueue<Completer<void>>();

  _SemaphoreImpl(this._permits) {
    if (_permits < 1) {
      throw ArgumentError.value(_permits, 'permits', 'must be at lease 1');
    }
  }

  @override
  Future<void>? acquire() {
    if (_current + 1 <= _permits) {
      ++_current;
      return null;
    } else {
      final signal = Completer<void>();
      _signals.add(signal);
      return signal.future;
    }
  }

  @override
  void release() {
    if (_current <= 0) {
      throw StateError('Cannot release this semaphore');
    }

    --_current;
    if (_current + 1 <= _permits && _signals.isNotEmpty) {
      ++_current;
      _signals.removeFirst().complete();
    }
  }
}

/// Executes the given [action], acquiring a permit from this semaphore at the beginning
/// and releasing it after the [action] is completed.
///
/// Returns the return value of the [action].
@experimental
extension SemaphoreExtension on Semaphore {
  /// Executes the given [action], acquiring a permit from this semaphore at the beginning
  /// and releasing it after the [action] is completed.
  ///
  /// Returns the return value of the [action].
  @experimental
  Future<T> withPermit<T>(Future<T> Function() action) async {
    await acquire();
    try {
      return await action();
    } finally {
      release();
    }
  }
}
