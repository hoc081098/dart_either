---
name: api-rename-flow
description: Guide for non-breaking public API renames in dart_either. Use this when renaming methods/functions while preserving compatibility and updating docs/tests.
---

# API Rename Flow Skill

## Purpose

Use this skill to rename public APIs in `dart_either` safely, with non-breaking migration first.

This skill is repository-local and intended for any AI coding agent working in this repo.

## When To Use

Apply this skill whenever an API method/function name is being changed, especially for Kotlin Arrow naming alignment.

## Required Workflow

1. Add the new API name with full docs and examples.
2. Keep the old API as an alias to the new API.
3. Mark the old API with `@Deprecated(...)` and include an explicit replacement name.
4. Update tests:
   - Add tests for the new API name.
   - Keep deprecated alias tests (add lint ignore only where needed).
5. Update documentation:
   - Update API listings/tables in `README.md`.
   - Update all code snippets in `README.md`.
6. Update code usage across the repository:
   - `example/**`
   - `lib/**` (including doc snippets)
   - `test/**` (except explicit deprecated alias tests)
7. Validate:
   - `dart analyze`
   - `dart test`

## Project Commands

```bash
dart analyze
dart test
```

## Done Checklist

- [ ] New API added.
- [ ] Old API kept as deprecated alias.
- [ ] Deprecation message points to replacement.
- [ ] Tests cover new API.
- [ ] Deprecated alias tests remain.
- [ ] `README.md` API list updated.
- [ ] `README.md` code snippets updated.
- [ ] `example/**` usage updated.
- [ ] Project-wide search shows old names only in deprecated aliases/tests/docs intentionally.
- [ ] `dart analyze` passes.
- [ ] `dart test` passes.

## Guardrails

- Do not remove deprecated aliases in the same change where new names are introduced.
- Do not introduce breaking API changes in rename-only PRs.
- Remove deprecated aliases only in a planned future major release.
