# Handoff: Dart `Raise` + `Cancellation` Effects

## Context

Tôi đang maintain một Dart FP library có `Either`, `EitherEffect`, `binding`, `bindingAsync`.

Hiện tại `EitherEffect<L>` đã có:

```dart
bind(...)
raise(...)
```

`raise()` đã implement xong.

Mental model hiện tại của `EitherEffect<L>`:

```text
EitherEffect<E>
├── bind(Either<E, A>) -> A
└── raise(E) -> Never
```

`bind(Left(e))` và `raise(e)` đều short-circuit khỏi current binding scope bằng internal control-flow mechanism.

Internal implementation đã có các concept kiểu:

```text
scope
token / identity
ControlError
short-circuit
catch only matching token
```

Tức architecture gần giống:

```text
Scala boundary.Label
boundary.break(value)
Break(label, value)
```

và compiler-agnostic version của Arrow Raise / YAES Raise.

---

# 1. Background mental model

Có hai hướng encode effects.

## Monad / effect-as-value style

Ví dụ:

```text
Either<E, A>
IO<A>
Reader<R, A>
State<S, A>
```

Kết hợp nhiều effect bằng transformer stack:

```scala
EitherT[Kleisli[IO, Env, *], Error, T]
```

gần:

```text
Env -> IO[Either[Error, T]]
```

MTL cải thiện coupling bằng capability constraints:

```scala
def compute[M[_]: Monad](input: Input)
  (using Raise[M, Error])
  (using Ask[M, Env]): M[T]
```

Business function mô tả WHAT capabilities nó cần thay vì fixed HOW effects được composed.

---

# 2. Direction muốn thử trong Dart

Thay vì monad stack / `TaskEither` / `ReaderTaskEither`, thử hướng:

> **direct-style typed effects for Dart**

Ví dụ:

```dart
Future<User> loadUser(
  UserId id,
  Raise<AppError> raise,
  Cancellation cancellation,
) async {
  cancellation.ensureActive();

  final user = await repository.find(id);

  if (user == null) {
    raise.raise(UserNotFound(id));
  }

  return user;
}
```

Business code vẫn:

```text
await
if
return
```

nhưng effect requirements explicit qua parameters.

Convention đang thấy hợp lý:

```text
business arguments first
effect capabilities last
```

Ví dụ:

```dart
checkout(
  cart,
  paymentMethod,
  raise,
  cancellation,
)
```

1–2 effect params vẫn đọc khá ổn.

3+ effects có thể bắt đầu noisy.

---

# 3. `Raise<E>` effect

## Desired abstraction

Nếu sau này tách khỏi `EitherEffect`, có thể có:

```dart
abstract interface class Raise<E> {
  Never raise(E error);
}
```

Có thể cân nhắc callable:

```dart
abstract interface class Raise<E> {
  Never call(E error);
}
```

để syntax:

```dart
raise(error);
```

thay vì:

```dart
raise.raise(error);
```

Nhưng hiện tại `EitherEffect<E>.raise()` đã implement xong, nên chưa cần rename vội.

---

# 4. Raise semantics

`Raise<E>` là typed non-local short-circuit.

```text
normal path
    |
    v
return A

failure path
    |
    v
raise(E)
    |
    v
abort current computation
    |
    v
handler
```

`raise()` phải return:

```dart
Never
```

để Dart flow analysis hiểu branch này không quay lại.

Ví dụ:

```dart
User loadUser(Raise<AppError> raise) {
  final user = findUser();

  if (user == null) {
    raise.raise(UserNotFound());
  }

  return user;
}
```

---

# 5. Difference from exceptions

Syntax/control flow khá giống:

```dart
throw error;
```

vs:

```dart
raise.raise(error);
```

Nhưng contract khác.

Exception:

```dart
Future<User> loadUser(UserId id)
```

không encode trong type rằng có thể fail với gì.

Raise:

```dart
Future<User> loadUser(
  UserId id,
  Raise<AppError> raise,
)
```

signature nói rõ:

```text
async
success -> User
typed failure -> AppError
```

Mental model:

> `Raise<E>` ~= typed throw capability

Nhưng không nên nói nó literally là exception semantics ở language level.

---

# 6. `Raise` should be independent from `Either`

Long-term preferred architecture:

```text
Raise<E>
= effect / capability

Either<E, A>
= one possible interpretation / handler result
```

Không nên thiết kế:

```text
Raise exists only as an Either helper
```

Preferred direction:

```text
Raise<E>
   |
   +-- either(...)
   +-- fold(...)
   +-- recover(...)
   +-- maybe orNull / getOrElse
```

Ví dụ:

```dart
final result = await Raise.either<AppError, User>(
  (raise) => loadUser(id, raise),
);
```

hoặc:

```dart
await Raise.fold<AppError, User, void>(
  (raise) => loadUser(id, raise),
  onRaise: handleError,
  onSuccess: handleUser,
);
```

Concept:

```text
same computation requiring Raise<E>
             |
             +-> Either<E, A>
             +-> fallback A
             +-> UI state
             +-> nullable
```

---

# 7. Current package direction

Recommendation so far:

Không tách package ngay.

Giữ trong library hiện tại trước, nhưng design abstraction boundary sạch.

Current package:

```text
dart_either
├── Either
├── EitherEffect
├── binding / bindingAsync
├── Raise-like semantics
└── internal control-flow runtime
```

Nếu sau này `Raise`, `Cancellation`, `Resource`, etc. lớn lên đủ mạnh:

```text
dart_effect
├── Raise
├── Cancellation
├── Resource
└── shared control runtime

dart_either
└── Either + Raise.either integration
```

Không extract package quá sớm.

---

# 8. Relationship with Scala boundary / YAES

Scala `boundary` roughly:

```scala
final class Label[-T]

def break[T](value: T)(using Label[T]): Nothing =
  throw Break(label, value)

inline def boundary[T](body: Label[T] ?=> T): T =
  create label
  try body(using label)
  catch matching Break(label, value)
```

Mental mapping to current Dart implementation:

```text
Scala                      Dart

Label<T>                   scope + token
break(value)               raise / bind(Left)
Break(label, value)        ControlError(token, value)
boundary                   binding scope
```

Key architecture:

```text
each boundary owns unique identity

inner scope must only catch
control signal belonging to itself

otherwise rethrow
```

---

# 9. Algebraic-effects terminology

Do NOT claim Dart implementation is a native algebraic effect system.

Better wording:

> algebraic-effect-inspired / effect-handler-style capability library

Native algebraic effect systems can support:

```text
perform operation
handler captures continuation
handler may resume continuation
```

Current `Raise` is abortive:

```text
raise(E)
→ exit
→ handler
```

No continuation resume.

Still conceptually follows:

```text
effect capability
operation
handler/interpreter
```

---

# 10. Cancellation effect

This is the harder part.

Important distinction:

```text
Raise
inside -> handler

Cancellation
outside -> scope -> inside -> handler
```

Cancellation requires external triggering.

---

# 11. Existing cancellation implementation worth reusing

There is an existing package:

```text
cancellation_token_hoc081098
```

with roughly:

```dart
final class CancellationToken {
  bool get isCancelled;

  void cancel();

  void guard();

  Future<T> guardFuture<T>(
    FutureOr<T> Function(CancellationToken token) action,
  );
}
```

`guardFuture` races:

```text
underlying Future
      |
      +------ Future.any ------+
      |                        |
cancellation completer --------+
```

So consumer can stop waiting immediately when cancelled.

Important:

```text
caller stops waiting ✅
underlying Future may still run ❌
```

because Dart `Future` has no built-in cancellation.

Cooperative checkpoints still required:

```dart
token.guard();
```

especially after awaits.

---

# 12. Existing Rx integration is actually quite good

There is already:

```dart
useCancellationToken(
  Future<T> Function(CancellationToken token) block,
)
```

implemented with Rx resource lifetime.

Rough semantics:

```text
subscription starts
    |
create CancellationToken
    |
run async block(token)
    |
subscription.cancel()
    |
token.cancel()
```

This is effectively:

```text
Rx subscription lifetime
→ cancellation scope lifetime
```

This is structured and should be preserved conceptually.

---

# 13. Existing issue to improve

Current old code sometimes maps:

```text
CancellationException
→ AppCancellationError
→ Either.Left<AppError>
```

then UI/BLoC does:

```dart
if (error.isCancellation) {
  ignore
}
```

Long-term effect model should avoid that.

Preferred split:

```text
Raise<AppError>
→ domain/application failure
→ value/error channel

Cancellation
→ lifetime/control-flow channel
→ normally not materialized as domain error
```

Cancellation should propagate to its owning cancellation boundary unless explicitly handled.

---

# 14. Cancellation API design

Need split ownership into two roles.

## External source / controller

Has permission to cancel.

```dart
final class CancellationController {
  Cancellation get cancellation;

  void cancel();
}
```

## Computation capability

Read-only/cooperative.

```dart
abstract interface class Cancellation {
  bool get isCancelled;

  void ensureActive();

  Future<T> guard<T>(Future<T> future);
}
```

Business code should receive:

```dart
Cancellation
```

not:

```dart
CancellationController
```

Deep functions must NOT get permission to cancel parent scope.

This mirrors conceptually:

```text
.NET CancellationTokenSource
vs
CancellationToken
```

---

# 15. Cancellation handler / boundary

Cancellation capability should only be created within a scope/handler.

Possible API:

```dart
final controller = CancellationController();

final result = await controller.run(
  (cancellation) async {
    return loadUser(
      id,
      raise,
      cancellation,
    );
  },
);
```

External:

```dart
controller.cancel();
```

Mental model:

```text
CancellationController
├── cancel()
└── run(block)
       |
       +-> creates scoped Cancellation capability
       +-> invokes block(capability)
       +-> catches matching cancellation control signal
```

---

# 16. Internal Cancellation control flow

Possible internal semantics:

```text
controller.cancel()
    |
    +-> cancelled = true
    +-> complete cancellation signal
```

Inside:

```dart
cancellation.ensureActive();
```

if cancelled:

```text
throw _Cancelled(scopeToken)
```

Handler catches only matching token:

```text
same token
→ handle cancellation

different token
→ rethrow
```

Nested scopes therefore behave correctly.

---

# 17. `ensureActive()` semantics

`ensureActive()` should terminate current cancellation scope.

```dart
void ensureActive() {
  if (cancelled) {
    throw _Cancelled(token);
  }
}
```

This is similar conceptually to Kotlin:

```text
ensureActive()
CancellationException
```

but implementation is Dart user-land.

---

# 18. `guard` / cancellable await

Possible API:

```dart
final user = await cancellation.guard(
  repository.find(id),
);
```

or callback style:

```dart
final user = await cancellation.awaitFuture(
  () => repository.find(id),
);
```

It should race operation and cancellation signal.

```text
operation Future -----------+
                            +-> first wins
cancel signal --------------+
```

If cancel wins:

```text
throw scoped cancellation control signal
```

Again:

```text
does NOT necessarily stop underlying Future
```

unless underlying API cooperates.

---

# 19. Interaction between Raise and Cancellation

Important rule:

```text
Raise handler must NOT swallow cancellation

Cancellation handler must NOT accidentally transform Raise into cancellation
```

Control signals should remain distinct.

Conceptually:

```text
control signal
├── Raised<E>
└── Cancelled
```

Each handler catches only its own signal/token.

---

# 20. Example full business signature

Preferred direct-style shape:

```dart
Future<Profile> loadProfile(
  UserId id,
  Raise<AppError> raise,
  Cancellation cancellation,
) async {
  cancellation.ensureActive();

  final user = await loadUser(
    id,
    raise,
    cancellation,
  );

  cancellation.ensureActive();

  if (!user.active) {
    raise.raise(UserInactive(id));
  }

  final settings = await loadSettings(
    id,
    raise,
    cancellation,
  );

  return Profile(user, settings);
}
```

This signature communicates:

```text
async
typed error: AppError
cancellable
success: Profile
```

without:

```text
Future<Either<AppError, Profile>>
TaskEither
ReaderTaskEither
monad transformer stack
```

---

# 21. Example handler boundary

Possible BLoC/UI boundary:

```dart
final controller = CancellationController();

final result = await controller.run(
  (cancellation) => Raise.either<AppError, Profile>(
    (raise) => loadProfile(
      id,
      raise,
      cancellation,
    ),
  ),
);
```

Need discuss exact return semantics for cancelled case.

Possible choices:

```text
Option A
Cancellation.run returns nullable
T?

Option B
Cancellation.run takes onCancelled

Option C
Cancellation.run exposes a CancellationResult<T>

Option D
cancelled scope completes silently / throws internal signal to outer owner
```

Do NOT pick blindly.

This is still open design work.

---

# 22. Cancellation result semantics: unresolved

Need decide what:

```dart
controller.run(...)
```

returns when cancelled.

Possible API:

```dart
Future<T> run<T>(
  Future<T> Function(Cancellation cancellation) block,
)
```

cannot return normal `T` after cancellation without inventing fake fallback.

Options:

### Explicit fallback

```dart
controller.run(
  block,
  onCancelled: () => fallback,
)
```

### Fold

```dart
Cancellation.fold(
  block,
  onCancelled: ...,
  onSuccess: ...,
)
```

### Dedicated result type

```dart
sealed class CancellationResult<T> {
  Success<T>
  Cancelled<T>
}
```

But this risks materializing cancellation into value channel again.

### Propagation

Cancellation boundary may only own lifetime but still propagate cancellation to a higher owner.

This requires careful semantics.

Need discuss with Codex.

---

# 23. Important rule

Never silently do:

```text
cancel
→ catch
→ return arbitrary fake T
```

unless user explicitly provided fallback.

Cancellation means:

> current computation is no longer valid / wanted

not:

> computation failed with domain value E

---

# 24. Resource effect idea

Future candidate:

```dart
Resource.run((resource) async {
  final file = await resource.acquire(
    () => openFile(),
    release: (file) => file.close(),
  );

  ...
});
```

Resource capability:

```dart
abstract interface class Resource {
  Future<R> acquire<R>(
    FutureOr<R> Function() acquire, {
    required FutureOr<void> Function(R) release,
  });
}
```

Handler maintains finalizer stack:

```text
acquire A
acquire B
acquire C

release C
release B
release A
```

LIFO.

Must release on:

```text
success
Raise
Cancellation
exception
```

Conceptual trio:

```text
Raise<E>
→ domain abort

Cancellation
→ lifetime abort

Resource
→ guaranteed cleanup
```

But Resource is future work, not current priority.

---

# 25. Proposed public library philosophy

If this grows beyond `dart_either`:

> Direct-style typed effects for Dart without monad stacks.

Core principles:

```text
1. direct-style async/await
2. typed capabilities
3. explicit effect requirements
4. scoped handlers
5. no hidden global ambient state
6. no monad-transformer ceremony
7. avoid pretending Dart has native algebraic effects
```

---

# 26. Effects worth prioritizing

High-value for Dart:

```text
Raise<E>
Cancellation
Resource
```

Possible later:

```text
Timeout
Retry
Environment / Reader-like capability
```

Be cautious with:

```text
State
Logger
Clock
Transaction
etc.
```

Do not add effects merely because effect systems can model them.

Every capability should solve a real Dart pain point.

---

# 27. Key open questions for Codex

Please analyze and challenge these:

1. Should `Raise<E>` become independent public abstraction now, or continue evolving from `EitherEffect<E>` first?

2. Should `Raise<E>` be:

```dart
raise.raise(error)
```

or callable:

```dart
raise(error)
```

3. What is the cleanest public shape for `Cancellation`?

```dart
CancellationController + Cancellation
```

or a different ownership model?

4. What should `Cancellation.run` return on cancellation?

5. Should cancellation use:

```text
scoped internal control signal + token
```

like current `EitherEffect`, or just `CancellationException`?

6. Should cancellation control signal be private and impossible for generic catch/mapping code to accidentally convert to domain error?

7. How should nested cancellation scopes work?

8. Should `guardFuture` accept:

```dart
Future<T>
```

or:

```dart
FutureOr<T> Function()
```

to avoid starting computation before cancellation check?

9. How should cancellation interoperate with:
   - Future
   - Stream
   - RxDart Single
   - HTTP requests
   - BLoC lifecycle

10. Should `Cancellation` expose:

```dart
ensureActive()
guard()
guardFuture()
guardStream()
```

or keep the core minimal and move adapters to extensions/modules?

11. Can `Raise` + `Cancellation` share one internal scoped-control runtime?

Example:

```text
_ControlScope
_ControlToken
_ControlSignal
```

with typed variants.

12. How to ensure generic:

```dart
catch (e)
```

helpers do not swallow control signals?

13. Should there be something like:

```dart
throwIfControlSignal(error)
```

similar to fatal-error filtering?

14. What invariants/tests are required for:
   - nested scopes
   - swallowed control signals
   - escaped capabilities
   - async scope lifetime
   - cancellation races
   - cleanup/finalizers

15. What API shape remains idiomatic Dart rather than cosplay Scala/Arrow?

---

# 28. Non-goals

Do NOT turn this into:

```text
dartz 2.0
fpdart clone
Scala Cats clone
Arrow old HKT style
```

Avoid:

```text
TaskEither
ReaderTaskEither
Monad transformer stacks
heavy HKT emulation
```

unless there is a compelling reason.

Goal is:

```text
direct-style Dart
+
typed effects
+
structured control
```

---

# 29. Desired Codex task

Please review this design as if designing a production-grade Dart effect library.

Focus on:

```text
Raise
Cancellation
scope ownership
handler semantics
nested effects
async behavior
control-signal safety
API ergonomics
backward compatibility with dart_either
```

Do not implement yet.

First produce:

```text
1. Recommended architecture
2. Public API proposal
3. Internal runtime model
4. Cancellation semantics
5. Raise semantics
6. Interaction between effects
7. Alternatives considered
8. Risks / edge cases
9. Test matrix
10. Migration path from current EitherEffect
```

Challenge questionable assumptions instead of agreeing automatically.
