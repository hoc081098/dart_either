# Arrow selective catch reference

This note records the exception-capture APIs in Arrow at commit
[`e28d8dd5`](https://github.com/arrow-kt/arrow/commit/e28d8dd5a4c8ed1ad9380f61a3eada408dbffbfd).
It is design evidence for selective capture in `dart_either`, not a claim that
the Kotlin API should be copied verbatim.

## Sources

- [`Either.kt`](https://github.com/arrow-kt/arrow/blob/e28d8dd5a4c8ed1ad9380f61a3eada408dbffbfd/arrow-libs/core/arrow-core/src/commonMain/kotlin/arrow/core/Either.kt#L845-L856):
  construction-time `Either.catch` and `Either.catchOrThrow`.
- [`Raise.kt`](https://github.com/arrow-kt/arrow/blob/e28d8dd5a4c8ed1ad9380f61a3eada408dbffbfd/arrow-libs/core/arrow-core/src/commonMain/kotlin/arrow/core/raise/Raise.kt#L438-L559):
  the four catch primitives to which those constructors delegate.

Supporting sources define Arrow's fatal boundary:
[`nonFatalOrThrow`](https://github.com/arrow-kt/arrow/blob/e28d8dd5a4c8ed1ad9380f61a3eada408dbffbfd/arrow-libs/core/arrow-exception-utils/src/commonMain/kotlin/arrow/core/nonFatalOrThrow.kt#L35-L40),
the [JVM and Android `NonFatal`](https://github.com/arrow-kt/arrow/blob/e28d8dd5a4c8ed1ad9380f61a3eada408dbffbfd/arrow-libs/core/arrow-exception-utils/src/androidAndJvmMain/kotlin/arrow/core/NonFatal.kt#L5-L10),
and the [`NonFatal` implementation on other targets](https://github.com/arrow-kt/arrow/blob/e28d8dd5a4c8ed1ad9380f61a3eada408dbffbfd/arrow-libs/core/arrow-exception-utils/src/nonJvmMain/kotlin/arrow/core/NonFatal.kt#L3-L8).

## Exact API shapes

The `Either` companion exposes two inline constructors:

```kotlin
inline fun <R> catch(f: () -> R): Either<Throwable, R>
inline fun <reified T : Throwable, R> catchOrThrow(f: () -> R): Either<T, R>
```

Both declare that `f` runs at most once. `catch` captures any non-fatal
`Throwable`. `catchOrThrow` captures a non-fatal throwable only when it is a
`T`; a non-matching throwable is rethrown. Only `T` is `reified`; `R` is an
ordinary type parameter. Both functions are also exposed as JVM static
methods. These facts follow directly from the declarations and delegations in
[`Either.kt`](https://github.com/arrow-kt/arrow/blob/e28d8dd5a4c8ed1ad9380f61a3eada408dbffbfd/arrow-libs/core/arrow-core/src/commonMain/kotlin/arrow/core/Either.kt#L845-L856).
`catchOrThrow` does not map `T` into another error type: the caught `T` itself
becomes the `Left` value.

`Raise.kt` supplies four inline overloads:

```kotlin
catch<A>(block: () -> A, catch: (Throwable) -> A): A
catch<A, B>(block: () -> A, transform: (A) -> B,
            catch: (Throwable) -> B): B
catch<reified T : Throwable, A>(block: () -> A, catch: (T) -> A): A
catch<reified T : Throwable, A, B>(block: () -> A,
                                   transform: (A) -> B,
                                   catch: (T) -> B): B
```

The typed overloads are also annotated `@JvmName("catchReified")`. All four
contracts mark every supplied callback as running at most once. The overloads
without `transform` require the success and recovery branches to produce the
same type `A`. The transform overloads let the block produce `A` while both
branches produce a common `B`: `transform` handles a successful `A`, and
`catch` handles a caught throwable. Arrow's `Either.catch` uses the untyped
transform overload with `Right` and `Left`; `Either.catchOrThrow` uses its
typed counterpart. The transform callback is therefore what lets the shared
primitive build an `Either` without first returning an unwrapped `R`.

## Catch and rethrow order

The base untyped primitive catches `Throwable`, immediately calls
`nonFatalOrThrow`, and passes the result to the recovery callback only when it
is non-fatal. The typed primitive delegates to that base and then checks
`t is T`. Consequently, its order is:

1. rethrow a fatal throwable;
2. invoke the typed handler for a non-fatal `T`;
3. rethrow a non-fatal throwable that is not a `T`.

An exception thrown by the recovery callback or success transform propagates;
neither callback is executed inside a second capture layer. The source also
shows that fatality is platform-specific. JVM and Android exclude
`VirtualMachineError`, `ThreadDeath`, `InterruptedException`, `LinkageError`,
and `CancellationException`; other targets exclude `CancellationException`.

Arrow separately defines an
[`Either<Throwable, A>.catch`](https://github.com/arrow-kt/arrow/blob/e28d8dd5a4c8ed1ad9380f61a3eada408dbffbfd/arrow-libs/core/arrow-core/src/commonMain/kotlin/arrow/core/Either.kt#L1587-L1623)
recovery extension. It handles an already stored `Left` of type `T`, may
produce a success or raise a new typed left value, and throws a non-matching
stored throwable. It is not a construction-time capture API.

## Implications for `dart_either`

Arrow provides source precedent for a separate type-directed constructor,
rather than a predicate parameter on its catch-all constructor. Its essential
contract is "capture matching non-fatal values and rethrow everything else".
The equivalent ordering in this package would have to preserve the existing
[`throwIfFatal`](../lib/src/dart_either.dart) check before testing the selected
type or invoking an `ErrorMapper`.

Arrow does not establish a Dart name or require Dart to reproduce the
transform overloads. Those overloads compensate for Kotlin's overloaded
top-level API and provide reusable branch construction internally. For this
package, the source supports a typed selective operation such as `catchOnly`
or `tryCatchOnly`. It does not provide evidence that a user-supplied predicate
is preferable, nor does its construction API establish the shape of a Dart
error mapper that also receives a `StackTrace`.

## Dart interface design

The existing capture seam is `ErrorMapper<L>`. `Either.tryCatch`,
`Either.tryCatchAsync`, `Future.toEitherFuture`, and `Stream.toEitherStream`
all apply `throwIfFatal` before invoking that mapper. A single typed mapper
adapter can therefore add selective capture to all four forms without adding
four parallel operations:

```dart
ErrorMapper<L> catchOnly<E extends Object, L>(
  L Function(E error, StackTrace stackTrace) errorMapper,
)
```

For a matching non-fatal `E`, the adapter invokes `errorMapper`. For a
non-matching error, it calls `Error.throwWithStackTrace` with the original
object and stack trace. Registered fatal errors and `ControlError` never reach
the adapter because every supported capture operation applies the existing
fatal guard first.

The call site keeps the established execution interface:

```dart
final Either<ParseFailure, int> result = Either.tryCatch(
  action: () => int.parse(input),
  errorMapper: catchOnly(
    (FormatException error, StackTrace stackTrace) =>
        ParseFailure(error.message),
  ),
);
```

Typing the mapper's first parameter makes `E` explicit while allowing Dart to
infer `E` and `L`. The same adapter composes with the asynchronous, Future, and
Stream capture interfaces. Regression coverage confirms that a matching error
becomes a `Left`, a non-match remains an error event, and later data events
continue through the existing transformer.

Two alternatives have weaker trade-offs for the current package:

- `tryCatchOnly<E, L, R>` and corresponding async/Future/Stream names are easy
  to discover but duplicate the same selection interface across execution
  forms. A selective factory cannot be used because Dart constructors cannot
  introduce an additional method-local type parameter `E`; it would have to
  be a static method.
- A public `ErrorCapture<E, L>` policy object can also unify all execution
  forms and support an additional predicate, but it adds a nominal type and
  four methods before the repository has a concrete need for reusable
  stateful capture policies or value-level predicates.

The accepted and implemented interface is the single `catchOnly` mapper
adapter. It keeps the public interface small, places type selection at the
existing seam, and concentrates type matching and non-match rethrow behavior
in one implementation. Arbitrary predicates and a reusable policy object
remain deferred until a consumer needs selection that cannot be expressed by
an error type.
