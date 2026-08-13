---
name: api-rename-flow
description: Safely introduce replacement names for public dart_either APIs without breaking compatibility. Use when renaming methods, aligning names with Arrow/Kotlin, or changing fallback naming or semantics across implementation, tests, changelog, README, examples, and repository docs.
---

# Non-breaking API rename workflow

1. Inspect the current declaration and compare the branch with `master`.
2. Add the canonical API with complete Dart docs and an accurate example.
3. Audit every `L` and `R` occurrence and the implementation using
   `docs/either-variance-safety.md`. Use a generic extension or top-level
   function when an instance-member position is unsafe, add widened regression
   tests where required, and apply `@covarianceSafe` only after the audit
   evidence is in place.
4. Keep the previous API as an `@Deprecated` alias when replacing an existing
   name. Preserve its behavior, including eager or lazy evaluation and callback
   arguments.
5. Test the canonical API in the main suite. Test deprecated aliases in
   `test/deprecated_aliases_test.dart`, using its single file-level lint ignore.
6. Update all public documentation in the same change:
   - `CHANGELOG.md`
   - API tables and code snippets in `README.md`
   - `docs/api-naming-alignment.md`
   - Contributor instructions such as `AGENTS.md` when they mention the API
7. Migrate normal usage across `lib/`, `example/`, and `test/`. Leave old names
   only in deprecated declarations, compatibility tests, and migration notes.
8. Search for stale names and verify the complete change:

```bash
dart analyze
dart test
git diff --check
```

Run `dart pub publish --dry-run` when the change is part of release preparation.

## Guardrails

- Do not remove a deprecated alias in the same release that introduces its
  replacement.
- Do not describe APIs with different evaluation timing as direct aliases.
- Do not expose deferred proposals as implemented APIs.
- Do not finish with README examples that differ from executable examples or
  public doc comments.
