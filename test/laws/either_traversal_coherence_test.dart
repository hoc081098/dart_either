import 'package:built_collection/built_collection.dart';
import 'package:dart_either/dart_either.dart';
import 'package:test/test.dart';

typedef _TraversalMapper = Either<String, String> Function(int value);

void main() {
  const inputs = <List<int>>[
    <int>[],
    <int>[-2, 0, 3],
    <int>[1, 2, 3],
  ];

  group('Traversal coherence', () {
    test('traverse matches sequence after mapping', () {
      final mappers = <String, _TraversalMapper>{
        'all right': (value) => Either<String, String>.right('value:$value'),
        'left for negative': (value) => value < 0
            ? Either<String, String>.left('negative:$value')
            : Either<String, String>.right('value:$value'),
        'left for zero': (value) => value == 0
            ? Either<String, String>.left('zero')
            : Either<String, String>.right('value:$value'),
        'all left': (value) => Either<String, String>.left('rejected:$value'),
      };

      for (final values in inputs) {
        for (final mapper in mappers.entries) {
          expect(
            Either.traverse<String, String, int>(values, mapper.value),
            Either.sequence<String, String>(values.map(mapper.value)),
            reason: 'values: $values, mapper: ${mapper.key}',
          );
        }
      }
    });

    test('right-only traverse matches ordered map wrapped in Right', () {
      final transforms = <String, int Function(int value)>{
        'increment': (value) => value + 1,
        'square': (value) => value * value,
      };

      for (final values in inputs) {
        for (final transform in transforms.entries) {
          expect(
            Either.traverse<String, int, int>(
              values,
              (value) => Either<String, int>.right(transform.value(value)),
            ),
            Either<String, BuiltList<int>>.right(
              BuiltList<int>.of(values.map(transform.value)),
            ),
            reason: 'values: $values, transform: ${transform.key}',
          );
        }
      }
    });
  });
}
