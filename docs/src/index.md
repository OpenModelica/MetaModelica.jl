```@meta
CurrentModule = MetaModelica
```

# MetaModelica.jl

MetaModelica.jl provides Julia implementations of MetaModelica runtime concepts used by OpenModelica.

It includes:

- Pattern matching macros such as `@match`, `@matchcontinue`, and `@unsafematch`.
- Union and record helpers such as `@Uniontype`, `@Mutable_Uniontype`, and `@Record`.
- Compacted uniontypes, one concrete tagged struct per uniontype: `@CUniontype` and `@T_Uniontype`, with `isvariant` and `variantof` in place of `isa` and `typeof`.
- Runtime compatibility functions for MetaModelica booleans, integers, reals, strings, arrays, lists, options, and values.

## Example

```julia
using MetaModelica

@match (1, 2) begin
  (x, y) => x + y
end
```

## API

See the [API Reference](@ref) for generated documentation from the package docstrings.
