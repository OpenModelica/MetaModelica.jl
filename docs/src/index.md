```@meta
CurrentModule = MetaModelica
```

# MetaModelica.jl

MetaModelica.jl provides Julia implementations of MetaModelica runtime concepts used by OpenModelica.

It includes:

- Pattern matching macros such as `@match`, `@matchcontinue`, and `@unsafematch`: see [Pattern matching](@ref).
- Uniontypes, MetaModelica's data types with a fixed set of record variants: `@Uniontype` with `@Record`, and the
  compacted forms `@T_Uniontype` and `@CUniontype` (one concrete struct per uniontype): see [Uniontypes](@ref).
- Runtime builtins: Julia versions of MetaModelica's builtin functions (see below).
- Function extension, `@ExtendedFunction` and `@ExtendedAnonFunction`, written for the MetaModelica-to-Julia
  translator: see [Function extension](@ref).

## Runtime builtins

The functions for MetaModelica booleans, integers, reals, strings, arrays, lists, options and values (`intAdd`,
`stringInt`, `listHead`, `arrayGet`, `valueEq`, ...) mimic MetaModelica's builtin functions: same names, same
arguments, same semantics, including failing with `fail()` where MetaModelica fails. They exist so that code
translated from MetaModelica, such as the OpenModelica frontend in OMFrontend.jl, runs unchanged.

They are not needed to use pattern matching. Julia code that only uses `@match` and `@matchcontinue` calls Julia's
own functions (`+`, `parse`, `first`, ...), and `fail()` to reject a `@matchcontinue` case.

## Example

```julia
using MetaModelica

@match (1, 2) begin
  (x, y) => x + y
end
```

## API

See the [API Reference](@ref) for generated documentation from the package docstrings.
