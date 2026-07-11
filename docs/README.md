# Project documentation

These documents record repository-level design decisions and maintenance
workflows. The public API documentation remains in Dart doc comments and the
root [README](../README.md). This directory is repository-only and excluded
from the published package through `.pubignore`.

- [API naming alignment](api-naming-alignment.md): implemented migrations,
  compatibility decisions, and deferred naming proposals.
- [Arrow Either reference](arrow-either-reference.md): upstream links and the
  boundary between Arrow inspiration and the Dart implementation.
- [API rename workflow](../.agents/skills/api-rename-flow/SKILL.md): the required
  process for non-breaking public API renames.

## Source of truth

When documents disagree, use this order:

1. Public declarations and doc comments under `lib/`.
2. Behavior covered by `test/`.
3. Release notes in `CHANGELOG.md` and usage examples in `README.md` and
   `example/`.
4. Design and planning notes in this directory.
