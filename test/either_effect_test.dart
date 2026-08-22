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

    test('raise supports safe contravariant narrowing', () {
      final result = Either<num, String>.binding((effect) {
        final EitherEffect<int> narrowed = effect;
        return narrowed.raise(1);
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
      final analysis = await _analyzeConsumerFixture(
        fileName: 'unsafe_either_effect_widen.dart',
        source: '''
import 'package:dart_either/dart_either.dart';

void reproduce() {
  Either<int, String>.binding((effect) {
    final EitherEffect<num> widened = effect;
    return widened.bind(Either<num, String>.left(1.5));
  });
}
''',
      );

      expect(analysis.exitCode, isNot(0), reason: analysis.output);
      expect(
        analysis.output,
        contains('ERROR|COMPILE_TIME_ERROR|INVALID_ASSIGNMENT|'),
        reason: analysis.output,
      );
    });

    test('rejects construction through the public typedef outside the library',
        () async {
      final analysis = await _analyzeConsumerFixture(
        fileName: 'external_either_effect_construction.dart',
        source: '''
import 'package:dart_either/dart_either.dart';

void reproduce() {
  final effect = EitherEffect<String>();
  print(effect);
}
''',
      );

      expect(analysis.exitCode, isNot(0), reason: analysis.output);
      expect(
        analysis.output,
        contains(
          'ERROR|COMPILE_TIME_ERROR|NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT|',
        ),
        reason: analysis.output,
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

Future<({int exitCode, String output})> _analyzeConsumerFixture({
  required String fileName,
  required String source,
}) async {
  final packageConfig = await Isolate.packageConfig;
  expect(packageConfig, isNotNull, reason: 'Package config is required.');

  final temporaryDirectory =
      await Directory.systemTemp.createTemp('dart_either_analyzer_');
  addTearDown(() => temporaryDirectory.delete(recursive: true));

  final fixture = File(
    '${temporaryDirectory.path}${Platform.pathSeparator}$fileName',
  );
  await fixture.writeAsString(source);

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

  return (
    exitCode: result.exitCode,
    output: '${result.stdout}\n${result.stderr}',
  );
}
