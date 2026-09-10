# Project documentation

These documents record repository-level design decisions and maintenance
workflows. The public API documentation remains in Dart doc comments and the
root [README](../README.md). This directory is repository-only and excluded
from the published package through `.pubignore`.

- [Domain language](../CONTEXT.md): canonical terms for `Either` value
  equality, binding scopes, binding capabilities, and short-circuiting.
- [API naming alignment](api-naming-alignment.md): implemented migrations,
  compatibility decisions, the major-version roadmap, and deferred proposals.
- [Arrow Either reference](arrow-either-reference.md): upstream links and the
  boundary between Arrow inspiration and the Dart implementation.
- [Either variance safety](either-variance-safety.md): signature variance,
  instance-method runtime checks, extension design, and widened-type tests.
- [Library strengths and improvement roadmap](library-strengths-and-improvement-roadmap.md):
  current capabilities, remaining design work, and the recommended application
  error-channel policy.
- [ADR 0001](adr/0001-scope-bound-contravariant-either-effect.md): why
  `EitherEffect` is an opaque, scope-bound, contravariant capability backed by
  a private binding scope.
- [ADR 0002](adr/0002-relocate-variance-unsafe-either-operations-to-extensions.md):
  why five variance-unsafe `Either` instance operations move to named generic
  extensions in `2.4.0`, including the accepted compatibility boundary.
- [ADR 0003](adr/0003-adopt-semantic-law-and-api-coherence-tests.md):
  why the implemented [algebraic-law and API-coherence suites](../test/laws)
  are permanent release gates without claiming type classes the package does
  not expose.
- [ADR 0004](adr/0004-define-either-value-equality-and-branch-aware-hashing.md):
  why `Either` equality ignores generic type arguments and hashing must combine
  a branch discriminator with the active payload hash.
- [API rename workflow](../.agents/skills/api-rename-flow/SKILL.md): the required
  process for non-breaking public API renames.

## Source of truth

When documents disagree, use this order:

1. Public declarations and doc comments under `lib/`.
2. Behavior covered by `test/`.
3. Release notes in `CHANGELOG.md` and usage examples in `README.md` and
   `example/`.
4. Design and planning notes in this directory.
