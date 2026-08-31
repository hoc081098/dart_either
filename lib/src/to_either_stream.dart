import 'dart:async';

import 'package:meta/meta.dart';

import 'dart_either.dart';

/// Provide [toEitherStream] extension on [Stream].
extension ToEitherStreamExtension<R> on Stream<R> {
  /// Transform data events to [Right]s and error events to [Left]s.
  ///
  /// When the source stream emits a data event, the result stream will emit
  /// a [Right] wrapping that data event.
  ///
  /// When the source stream emits an error event, [errorMapper] maps that error
  /// and the result stream emits a [Left] wrapping the mapped value.
  /// Errors matching [Either.registerFatalError] are rethrown instead.
  ///
  /// When the source stream closes, the returned stream also closes with a
  /// done event.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final Stream<int> s = Stream.fromIterable([1, 2, 3, 4]);
  /// final Stream<Either<Object, int>> eitherStream = s.toEitherStream((e, s) => e);
  ///
  /// eitherStream.listen(print); // prints Either.Right(1),
  ///                             //        Either.Right(2),
  ///                             //        Either.Right(3),
  ///                             //        Either.Right(4),
  /// ```
  @useResult
  Stream<Either<L, R>> toEitherStream<L>(ErrorMapper<L> errorMapper) =>
      transform(
        StreamTransformer<R, Either<L, R>>.fromHandlers(
          handleData: (data, sink) => sink.add(Either.right(data)),
          handleError: (error, stackTrace, sink) => sink.add(
            Either.left(
              errorMapper(
                throwIfFatal(error, stackTrace),
                stackTrace,
              ),
            ),
          ),
        ),
      );
}
