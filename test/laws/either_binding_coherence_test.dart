import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

typedef _BindingStep = Either<String, int> Function(int value);

Future<T> _afterAsyncSuspension<T>(T value) async {
  await Future<void>.delayed(Duration.zero);
  return value;
}

void main() {
  final bindingCases = <({
    String name,
    Either<String, int> first,
    _BindingStep second,
  })>[
    (
      name: 'success',
      first: const Right<String, int>(2),
      second: (value) => Either<String, int>.right(value * 3),
    ),
    (
      name: 'left at the first step',
      first: const Left<String, int>('first'),
      second: (value) => Either<String, int>.right(value * 3),
    ),
    (
      name: 'left at a later step',
      first: const Right<String, int>(2),
      second: (value) => Either<String, int>.left('later:$value'),
    ),
  ];

  group('Either.binding coherence', () {
    for (final bindingCase in bindingCases) {
      test('${bindingCase.name} matches an explicit flatMap pipeline', () {
        final viaBinding = Either<String, int>.binding((effect) {
          final first = bindingCase.first.bind(effect);
          final second = bindingCase.second(first).bind(effect);
          return first + second;
        });
        final viaFlatMap = bindingCase.first.flatMap(
          (first) => bindingCase.second(first).map(
                (second) => first + second,
              ),
        );

        expect(viaBinding, viaFlatMap);
      });
    }

    test('binding a Left matches raising the same value', () {
      final viaBind = Either<String, int>.binding(
        (effect) => effect.bind(const Left<String, int>('stop')),
      );
      final viaRaise = Either<String, int>.binding(
        (effect) => effect.raise('stop'),
      );

      expect(viaBind, viaRaise);
    });

    for (final condition in <bool>[true, false]) {
      test('ensure ${condition ? 'continues for true' : 'raises for false'}',
          () {
        final result = Either<String, int>.binding((effect) {
          effect.ensure(condition, () => 'ensure failed');
          return 42;
        });
        final expected = condition
            ? const Right<String, int>(42)
            : const Left<String, int>('ensure failed');

        expect(result, expected);
      });
    }

    test('ensureNotNull returns a non-null value', () {
      final result = Either<String, int>.binding((effect) {
        final value = effect.ensureNotNull(2, () => 'missing');
        return value + 1;
      });

      expect(result, const Right<String, int>(3));
    });

    test('ensureNotNull raises for null', () {
      final result = Either<String, int>.binding((effect) {
        final value = effect.ensureNotNull<int>(null, () => 'missing');
        return value + 1;
      });

      expect(result, const Left<String, int>('missing'));
    });
  });

  group('Either.bindingAsync coherence', () {
    for (final bindingCase in bindingCases) {
      test(
        '${bindingCase.name} matches an explicit async extension pipeline',
        () async {
          final viaBinding = await Either.bindingAsync<String, int>(
            (effect) async {
              final first =
                  await _afterAsyncSuspension(bindingCase.first).bind(effect);
              final second = await _afterAsyncSuspension(
                bindingCase.second(first),
              ).bind(effect);
              await Future<void>.delayed(Duration.zero);
              return second + 1;
            },
          );
          final viaExtensions = await _afterAsyncSuspension(bindingCase.first)
              .thenFlatMapEither(
            (first) => _afterAsyncSuspension(
              bindingCase.second(first),
            ),
          )
              .thenMapEither((second) async {
            await Future<void>.delayed(Duration.zero);
            return second + 1;
          });

          expect(viaBinding, viaExtensions);
        },
      );
    }

    test('binding a Left matches raising the same value', () async {
      final viaBind = await Either.bindingAsync<String, int>((effect) async {
        await Future<void>.delayed(Duration.zero);
        return effect.bind(const Left<String, int>('stop'));
      });
      final viaRaise = await Either.bindingAsync<String, int>((effect) async {
        await Future<void>.delayed(Duration.zero);
        return effect.raise('stop');
      });

      expect(viaBind, viaRaise);
    });

    for (final condition in <bool>[true, false]) {
      test('ensure ${condition ? 'continues for true' : 'raises for false'}',
          () async {
        final result = await Either.bindingAsync<String, int>((effect) async {
          await Future<void>.delayed(Duration.zero);
          effect.ensure(condition, () => 'ensure failed');
          return 42;
        });
        final expected = condition
            ? const Right<String, int>(42)
            : const Left<String, int>('ensure failed');

        expect(result, expected);
      });
    }

    test('ensureNotNull returns a non-null value', () async {
      final result = await Either.bindingAsync<String, int>((effect) async {
        await Future<void>.delayed(Duration.zero);
        final value = effect.ensureNotNull(2, () => 'missing');
        return value + 1;
      });

      expect(result, const Right<String, int>(3));
    });

    test('ensureNotNull raises for null', () async {
      final result = await Either.bindingAsync<String, int>((effect) async {
        await Future<void>.delayed(Duration.zero);
        final value = effect.ensureNotNull<int>(null, () => 'missing');
        return value + 1;
      });

      expect(result, const Left<String, int>('missing'));
    });
  });
}
