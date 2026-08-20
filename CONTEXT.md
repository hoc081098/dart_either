# dart_either

This context defines the language used for typed failure and sequential
short-circuiting in `dart_either`.

## Language

**Either**:
A value containing either a typed undesired value on the left or a desired
value on the right.
_Avoid_: Result, response wrapper

**Binding scope**:
The lifetime of one `Either.binding` or `Either.futureBinding` computation.
_Avoid_: Global context, coroutine scope

**Binding capability (`EitherEffect`)**:
Package-issued authority supplied by a binding scope to obtain an `Either`'s
right value or terminate that scope with a left value of the same type. Its
record brand is an implementation marker, not part of the domain operation.
_Avoid_: Context object, effect object, effect system

**Short-circuit**:
Termination of a binding scope with its first bound left value, without
evaluating the remaining steps.
_Avoid_: Exception handling, failure conversion
