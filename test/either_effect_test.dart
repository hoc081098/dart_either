import 'dart:io';
import 'dart:isolate';

import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

void main() {
  group('EitherEffect', () {
    test('supports safe contravariant narrowing', () {
      final result = Either<num, String>.binding((effect) {
        final EitherEffect<int> narrowed = effect;
        return narrowed.bind(Either<int, String>.left(1));
      });

      expect(result, Left<num, String>(1));
    });

    test('binds widened Either runtime subtypes without a type error', () {
      final Either<int, String> widenedLeft = const Left<int, Never>(1);
      final Either<String, num> widenedRight = const Right<Never, int>(2);

      expect(
        Either<int, String>.binding(
          (effect) => effect.bind(widenedLeft),
        ),
        Left<int, String>(1),
      );
      expect(
        Either<String, num>.binding(
          (effect) => effect.bind(widenedRight),
        ),
        Right<String, num>(2),
      );
    });

    test('rejects unsafe widening during static analysis', () async {
      final packageConfig = await Isolate.packageConfig;
      expect(packageConfig, isNotNull, reason: 'Package config is required.');

      final temporaryDirectory =
          await Directory.systemTemp.createTemp('dart_either_variance_');
      addTearDown(() => temporaryDirectory.delete(recursive: true));

      final fixture = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}'
        'unsafe_either_effect_widen.dart',
      );
      await fixture.writeAsString('''
import 'package:dart_either/dart_either.dart';

void reproduce() {
  Either<int, String>.binding((effect) {
    final EitherEffect<num> widened = effect;
    return widened.bind(Either<num, String>.left(1.5));
  });
}
''');

      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          '--packages=${packageConfig!.toFilePath()}',
          'analyze',
          '--format=machine',
          fixture.path,
        ],
        environment: <String, String>{
          ...Platform.environment,
          'CI': 'true',
        },
      );
      final analyzerOutput = '${result.stdout}\n${result.stderr}';

      expect(result.exitCode, isNot(0), reason: analyzerOutput);
      expect(
        analyzerOutput,
        contains('ERROR|COMPILE_TIME_ERROR|INVALID_ASSIGNMENT|'),
        reason: analyzerOutput,
      );
    });

    test('nested binding catches only its own short-circuit', () {
      final result = Either<String, int>.binding((outerEffect) {
        return Either<String, int>.binding((innerEffect) {
          return outerEffect.bind(Either<String, int>.left('outer'));
        }).bind(outerEffect);
      });

      expect(result, Left<String, int>('outer'));
    });

    test('nested futureBinding catches only its own short-circuit', () async {
      final result = await Either.futureBinding<String, int>(
        (outerEffect) async {
          final inner = await Either.futureBinding<String, int>(
            (innerEffect) async {
              await Future<void>.delayed(Duration.zero);
              return outerEffect.bind(Either<String, int>.left('outer'));
            },
          );
          return inner.bind(outerEffect);
        },
      );

      expect(result, Left<String, int>('outer'));
    });

    test('rejects a captured capability after binding returns', () {
      late EitherEffect<String> captured;

      final result = Either<String, int>.binding((effect) {
        captured = effect;
        return 1;
      });

      expect(result, Right<String, int>(1));
      expect(
        () => captured.bind(Either<String, int>.right(2)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'EitherEffect was used outside its binding scope.',
          ),
        ),
      );
    });

    test('rejects a captured capability after futureBinding settles', () async {
      late EitherEffect<String> captured;

      final result = await Either.futureBinding<String, int>((effect) async {
        captured = effect;
        await Future<void>.delayed(Duration.zero);
        return 1;
      });

      expect(result, Right<String, int>(1));
      expect(
        () => captured.bind(Either<String, int>.right(2)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'EitherEffect was used outside its binding scope.',
          ),
        ),
      );
    });

    test('rejects an intercepted binding short-circuit', () {
      expect(
        () => Either<String, int>.binding((effect) {
          try {
            effect.bind(Either<String, int>.left('failure'));
          } on ControlError<String> catch (error) {
            expect(error, isA<ControlError<String>>());
          }
          return 1;
        }),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Binding short-circuit was intercepted.',
          ),
        ),
      );
    });

    test('rejects an intercepted futureBinding short-circuit', () async {
      await expectLater(
        Either.futureBinding<String, int>((effect) async {
          try {
            effect.bind(Either<String, int>.left('failure'));
          } on ControlError<String> catch (error) {
            expect(error, isA<ControlError<String>>());
          }
          return 1;
        }),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Binding short-circuit was intercepted.',
          ),
        ),
      );
    });
  });
}
