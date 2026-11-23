```@meta
CurrentModule = MetaModelica
```

# Function extension

[`@ExtendedFunction`](@ref) and [`@ExtendedAnonFunction`](@ref) define a function that calls an existing function
with other default values. They were written for the automatic translator from MetaModelica to Julia, as Julia
versions of two MetaModelica constructs:

| MetaModelica                                                   | Julia                                                        |
|----------------------------------------------------------------|--------------------------------------------------------------|
| `function pathStringNoQual = pathString(usefq = false);`       | `@ExtendedFunction pathStringNoQual pathString(usefq = false)` |
| `function pathString(usefq = false)`, passed as an argument    | `@ExtendedAnonFunction pathString(usefq = false)`            |

Like the [runtime builtins](@ref "Runtime builtins"), they exist for code translated from MetaModelica. OMFrontend.jl
and OMBackend.jl do not use them. Hand-written Julia code does the same with a method or a closure:

```julia
pathStringNoQual(path::String, delimiter::String = ".") = pathString(path, delimiter, false)
f = path -> pathString(path, ".", false)
```

## `@ExtendedFunction new old(arg = value, ...)`

Defines `new` with the positional arguments of `old`, in the same order. Each named argument gets the new default;
the other arguments keep the defaults of `old`, and an argument without a default stays required. `new` passes
all arguments on to `old`.

```@example extension
using MetaModelica

pathString(path::String, delimiter::String = ".", usefq::Bool = true) =
  (usefq ? "." : "") * replace(path, "/" => delimiter)

@ExtendedFunction pathStringNoQual pathString(usefq = false)

(pathString("a/b"), pathStringNoQual("a/b"), pathStringNoQual("a/b", "::"))
```

A default can also be given to an argument that had none, which makes it optional:

```@example extension
@ExtendedFunction pathStringAB pathString(path = "a/b")

pathStringAB()
```

An extended function can be extended again.

## `@ExtendedAnonFunction old(arg = value, ...)`

The same, as an anonymous function: a value to pass where a function is expected.

```@example extension
applyTo(f::Function, paths::Vector{String}) = map(f, paths)

applyTo(@ExtendedAnonFunction(pathString(usefq = false)), ["a/b", "c/d"])
```

## Limits

- The macro reads the methods of `old` when it expands: `old` must be defined before the macro, and be a plain
  name in the current module (`old`, not `Mod.old`).
- Only positional arguments get new defaults. Keyword arguments of `old` keep theirs.
- The defaults of `old` must be literals (numbers, strings, symbols, `true`, `false`) or constants (`nothing`, a
  `const` global). A default computed from an expression, such as `b = a + 1`, is an error when the macro
  expands.
- For a function with several methods, the method with the most arguments is the one extended.
