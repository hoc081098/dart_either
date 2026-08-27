// MICROBENCHMARK
//
// Question: how much end-to-end overhead does synchronous `Either.binding`
// add compared with an equivalent `flatMap` pipeline on success and on a late
// `Left` short-circuit?
//
// Run with:
// dart run benchmark/flat_map_vs_binding_benchmark.dart
//
// Run as AOT with:
// dart compile exe benchmark/flat_map_vs_binding_benchmark.dart \
//   -o .dart_tool/flat_map_vs_binding_benchmark
// .dart_tool/flat_map_vs_binding_benchmark
//
// Compare results only on the same machine and runtime. Scores are
// microseconds per complete pipeline; lower is better.

import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:dart_either/dart_either.dart';

const Either<String, int> _zero = Either<String, int>.right(0);
const Either<String, int> _failure =
    Either<String, int>.left('benchmark failure');

Either<String, int> _increment(int value) =>
    Either<String, int>.right(value + 1);

Either<String, int> _fail(int _) => _failure;

Either<String, int> _flatMapSuccess(int steps) {
  var result = _zero;

  for (var index = 0; index < steps; index++) {
    result = result.flatMap(_increment);
  }

  return result;
}

Either<String, int> _bindingSuccess(int steps) =>
    Either<String, int>.binding((effect) {
      var value = 0;

      for (var index = 0; index < steps; index++) {
        value = effect.bind(_increment(value));
      }

      return value;
    });

Either<String, int> _flatMapLateLeft(int steps) {
  var result = _zero;

  for (var index = 1; index < steps; index++) {
    result = result.flatMap(_increment);
  }

  return result.flatMap(_fail);
}

Either<String, int> _bindingLateLeft(int steps) =>
    Either<String, int>.binding((effect) {
      var value = 0;

      for (var index = 1; index < steps; index++) {
        value = effect.bind(_increment(value));
      }

      return effect.bind(_fail(value));
    });

abstract class _EitherBenchmark extends BenchmarkBase {
  _EitherBenchmark(super.name, this.steps, this.expected);

  final int steps;
  final Either<String, int> expected;

  Either<String, int> _result = _zero;

  @override
  void exercise() => run();

  @override
  void teardown() {
    if (_result != expected) {
      throw StateError('$name produced $_result; expected $expected.');
    }
  }
}

final class _FlatMapSuccessBenchmark extends _EitherBenchmark {
  _FlatMapSuccessBenchmark(int steps)
      : super(
          'flatMap success ($steps steps)',
          steps,
          Either<String, int>.right(steps),
        );

  @override
  void run() {
    _result = _flatMapSuccess(steps);
  }
}

final class _BindingSuccessBenchmark extends _EitherBenchmark {
  _BindingSuccessBenchmark(int steps)
      : super(
          'binding success ($steps binds)',
          steps,
          Either<String, int>.right(steps),
        );

  @override
  void run() {
    _result = _bindingSuccess(steps);
  }
}

final class _FlatMapLateLeftBenchmark extends _EitherBenchmark {
  _FlatMapLateLeftBenchmark(int steps)
      : super('flatMap late Left ($steps steps)', steps, _failure);

  @override
  void run() {
    _result = _flatMapLateLeft(steps);
  }
}

final class _BindingLateLeftBenchmark extends _EitherBenchmark {
  _BindingLateLeftBenchmark(int steps)
      : super('binding late Left ($steps binds)', steps, _failure);

  @override
  void run() {
    _result = _bindingLateLeft(steps);
  }
}

final class _Comparison {
  const _Comparison(this.label, this.flatMap, this.binding);

  final String label;
  final _EitherBenchmark flatMap;
  final _EitherBenchmark binding;
}

void main() {
  final List<_Comparison> comparisons = <_Comparison>[
    _Comparison(
      'success / 1 step',
      _FlatMapSuccessBenchmark(1),
      _BindingSuccessBenchmark(1),
    ),
    _Comparison(
      'success / 10 steps',
      _FlatMapSuccessBenchmark(10),
      _BindingSuccessBenchmark(10),
    ),
    _Comparison(
      'late Left / 10 steps',
      _FlatMapLateLeftBenchmark(10),
      _BindingLateLeftBenchmark(10),
    ),
  ];

  print('MICROBENCHMARK: flatMap vs synchronous Either.binding');
  print('Dart ${Platform.version}');
  print('Scores: microseconds per complete pipeline (lower is better).');
  print('A binding/flatMap ratio above 1 means binding is slower.');
  print('');
  print(
    '${'Scenario'.padRight(26)}'
    '${'flatMap'.padLeft(14)}'
    '${'binding'.padLeft(14)}'
    '${'binding/flatMap'.padLeft(18)}',
  );

  for (final comparison in comparisons) {
    final flatMapScore = comparison.flatMap.measure();
    final bindingScore = comparison.binding.measure();
    final ratio = bindingScore / flatMapScore;

    print(
      '${comparison.label.padRight(26)}'
      '${flatMapScore.toStringAsFixed(6).padLeft(14)}'
      '${bindingScore.toStringAsFixed(6).padLeft(14)}'
      '${('${ratio.toStringAsFixed(2)}x').padLeft(18)}',
    );
  }
}
