# Arrow Either reference

`dart_either` uses Arrow's Kotlin `Either` API as a semantic and naming
reference. Arrow is not a runtime dependency, and no Arrow source file is
vendored in this repository.

- [Arrow Either API documentation](https://apidocs.arrow-kt.io/arrow-core/arrow.core/-either/index.html)
- [Arrow Either source](https://github.com/arrow-kt/arrow/blob/main/arrow-libs/core/arrow-core/src/commonMain/kotlin/arrow/core/Either.kt)
- [Arrow license](https://github.com/arrow-kt/arrow/blob/main/LICENSE)

Arrow is a reference rather than a one-to-one compatibility contract. Adapt
APIs to Dart's type system and conventions, preserve this package's published
compatibility guarantees, and record naming decisions in
[API naming alignment](api-naming-alignment.md).
