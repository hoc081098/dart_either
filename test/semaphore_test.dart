import 'dart:math';

import 'package:dart_either/src/utils/semaphore.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() async {
  group('Semaphore', () {
    test('Constructor', () {
      expect(() => Semaphore(0), throwsArgumentError);
      expect(() => Semaphore(-1), throwsArgumentError);
      Semaphore(1);
    });

    test('acquire and release', () async {
      final sm = Semaphore(2);

      expect(sm.acquire(), isNull);
      expect(sm.acquire(), isNull);

      final acquire1 = sm.acquire();
      final acquire2 = sm.acquire();
      expect(acquire1, isNotNull);
      expect(acquire2, isNotNull);

      sm.release();
      sm.release();

      await pumpEventQueue();
      expect(acquire1, completes);
      expect(acquire2, completes);

      sm.release();
      sm.release();
      expect(() => sm.release(), throwsStateError);
    });

    test('Semaphore', () async {
      final maxCount = 3;
      final sm = Semaphore(maxCount);

      final running = <int>[];
      var simultaneous = 0;

      final tasks = <Future<void>>[];
      for (var i = 0; i < 9; i++) {
        tasks.add(
          sm.withPermit(() async {
            running.add(i);
            simultaneous = max(simultaneous, running.length);
            print('Start $i, running $running');

            await _doWork(50);

            running.remove(i);
            print('End   $i, running $running');
          }),
        );
      }

      await Future.wait(tasks);
      expect(simultaneous, lessThanOrEqualTo(maxCount));
      print('Max permits: $maxCount, max simultaneous runned: $simultaneous');
    });
  });
}

Future<void> _doWork(int ms) {
  // Simulate work
  return Future<void>.delayed(Duration(milliseconds: ms));
}
