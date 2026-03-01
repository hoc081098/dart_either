This file tracks naming alignment proposals to make the Dart API feel closer to Arrow/Kotlin while staying idiomatic in Dart.

| Current Dart API      | Suggested Name                    | Rationale                                      | Status |
|-----------------------|-----------------------------------|------------------------------------------------|--------|
| `tap`                 | `onRight`                         | Matches Arrow mental model                     | DONE   |
| `tapLeft`             | `onLeft`                          | Matches Arrow mental model                     | DONE   |
| `orNull`              | `getOrNull`                       | Aligns with Kotlin/Arrow naming                | DONE   |
| `getOrHandle`         | `getOrElse`                       | Semantics match Arrow `getOrElse((L) -> R)`    |        |
| `getOrElse(() => R)`  | `getOrDefault` or `orElseGet`     | Disambiguates from `getOrElse((L) -> R)` style | DONE   |
| `exists`              | `isRightAnd` or `isRightWhere`    | Closer to `isRight(predicate)` semantics       | DONE   |
| *(not available yet)* | `isLeftAnd` or `isLeftWhere`      | Symmetric pair with `isRightAnd`               |        |
| `handleError`         | `recover`                         | Closer to Arrow naming                         |        |
| `handleErrorWith`     | `recoverWith` *(or keep current)* | Keeps naming family aligned with `recover`     |        |
| `catchError`          | `catch`                           | Shorter and aligned with Arrow                 |        |
| `catchFutureError`    | `catchFuture`                     | Naming consistency with `catch`                |        |
| `catchStreamError`    | `catchStream`                     | Naming consistency with `catch`                |        |

Safe rollout guidance (published package):

1. Introduce the new name first.
2. Keep the old name as an alias and mark it `@Deprecated` with replacement guidance.
3. Remove deprecated APIs only in a future major release (after 1-2 minor releases).
