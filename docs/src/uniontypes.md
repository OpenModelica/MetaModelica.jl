```@meta
CurrentModule = MetaModelica
```

# Uniontypes

A MetaModelica uniontype is a type with a fixed set of variants, the records. With [Pattern matching](@ref) it is
the main data structure of OMFrontend.jl: expressions, types, equations and the instance tree are uniontypes.

```modelica
uniontype Exp
  record INT
    Integer value;
  end INT;
  record ADD
    Exp lhs;
    Exp rhs;
  end ADD;
end Exp;
```

MetaModelica.jl has three ways to write one in Julia:

| Macro                          | Expands to                                                      | Variant of a value  |
|--------------------------------|-----------------------------------------------------------------|---------------------|
| [`@Uniontype`](@ref)           | an abstract type `Exp`, one struct per record                   | `typeof`, `isa`     |
| [`@T_Uniontype`](@ref)         | one concrete struct `ExpImpl` with a `tag` field for all variants | `variantof`, `isvariant` |
| [`@CUniontype`](@ref)          | one concrete struct `ExpData`, for variants that extend each other | `variantof`, `isvariant` |

`@match` and `@matchcontinue` match all three the same way: `INT(v)`, `ADD(l, r)`.

## `@Uniontype` and `@Record`

```@example union
using MetaModelica

@Uniontype Exp begin
  @Record INT begin
    value::Int
  end
  @Record ADD begin
    lhs::Exp
    rhs::Exp
  end
end

evaluate(e::Exp)::Int = @match e begin
  INT(v) => v
  ADD(l, r) => evaluate(l) + evaluate(r)
end

evaluate(ADD(INT(1), ADD(INT(2), INT(3))))
```

This is the same as writing

```julia
abstract type Exp end
struct INT <: Exp
  value::Int
end
struct ADD <: Exp
  lhs::Exp
  rhs::Exp
end
```

so each record is an ordinary immutable struct: it is constructed with its fields in order, `isa` and `typeof`
tell the variant, and methods can dispatch on it.

```@example union
(INT(1) isa Exp, typeof(ADD(INT(1), INT(2))), isabstracttype(Exp))
```

Other forms:

- **Docstring.** `@Uniontype "An integer expression." Exp begin ... end` attaches the string to `Exp`. A string
  before the macro (`"..." @Uniontype ...`) does not work: the macro expands to several definitions.
- **Short records.** `@Record IMG r::Float64 i::Float64` is `@Record IMG begin r::Float64; i::Float64 end`.
  `@Record EMPTY` is a record without fields.
- **Mutable records.** [`@Mutable_Uniontype`](@ref) has the same syntax and makes every record a
  `mutable struct`.
- **Type parameters.** `@Uniontype Box{T} begin @Record FULL begin x::T end end` gives `FULL{T} <: Box{T}`; a
  record can also have parameters of its own (`@Record WRAP{S} begin ... end`).

```@example union
@Uniontype Num begin
  @Record REAL r::Float64
  @Record IMG r::Float64 i::Float64
  @Record ZERO
end

@Mutable_Uniontype Counter begin
  @Record COUNT begin
    n::Int
  end
end

c = COUNT(1)
c.n = 2
(IMG(1.0, 2.0), ZERO(), c.n)
```

### Types that refer to each other: `@UniontypeDecl`

A field type must exist before the struct that uses it. When two uniontypes refer to each other, declare the
second one first with [`@UniontypeDecl`](@ref MetaModelica.UniontypeDef.@UniontypeDecl):

```@example union
@UniontypeDecl Stmt

@Uniontype Ast begin
  @Record LAMBDA begin
    body::Stmt
  end
  @Record CONST begin
    v::Int
  end
end

@Uniontype Stmt begin
  @Record RETURN begin
    e::Ast
  end
end

RETURN(LAMBDA(RETURN(CONST(1)))) isa Stmt
```

A uniontype that refers only to itself (`ADD` above) needs no declaration.

## Compacted uniontypes

With `@Uniontype`, a field or a container of type `Exp` has an abstract type: Julia stores each value boxed and
finds the record's type at run time.

```@example union
typeof([INT(1), ADD(INT(1), INT(2))])
```

A compacted uniontype is one concrete struct for all its variants, with a `tag` field that says which variant a
value is. Fields and containers of that type are concrete. The variants are constructor functions, not types.
OMFrontend.jl uses compacted uniontypes for some of its recursive types: component references, dimensions,
bindings, modifiers.

### `@T_Uniontype`

```@example union
@T_Uniontype Shape begin
  POINT()
  CIRCLE(r::Float64)
  RECT(w::Float64, h::Float64)
end

area(s::Shape)::Float64 = @match s begin
  POINT() => 0.0
  CIRCLE(r) => pi * r^2
  RECT(w, h) => w * h
end

(area.([POINT(), CIRCLE(1.0), RECT(2.0, 3.0)]), typeof([CIRCLE(1.0), RECT(1.0, 1.0)]))
```

`Shape` is an abstract type and `ShapeImpl <: Shape` the struct. It holds the tag and the fields of all variants,
in the order they are first seen. A variant without a field stores the field's default, if some variant declares
one (`filled::Bool = false`), else `nothing`; such a field is typed `Union{Nothing, T}`:

```@example union
(fieldnames(ShapeImpl), fieldtypes(ShapeImpl))
```

The variants are constructed positionally (`RECT(2.0, 3.0)`), positionally with trailing defaults left out, or
with keywords (`RECT(; w = 2.0, h = 3.0)`). A variant without fields is one shared value.
`@T_Uniontype mutable Name begin ... end` makes the struct mutable.

### `@CUniontype`

For variants that extend each other: each variant's fields are the first fields of the next larger one. Then no
field needs `nothing`, and every field keeps its own type.

```@example union
@CUniontype Path begin
  ROOT()
  NAME(name::String, parent::Path)
end

depth(p::Path)::Int = @match p begin
  ROOT() => 0
  NAME(_, parent) => 1 + depth(parent)
end

(depth(NAME("b", NAME("a", ROOT()))), fieldtypes(PathData))
```

Variants with fields that do not extend each other are an error when `@CUniontype` expands: use `@T_Uniontype`.

### `isvariant` and `variantof`

All variants of a compacted uniontype have the same type, so `isa` and `typeof` do not tell them apart.
[`isvariant`](@ref) and [`variantof`](@ref) do; on other values they are `isa` and the type.

```@example union
(CIRCLE(1.0) isa ShapeImpl, RECT(1.0, 1.0) isa ShapeImpl, isvariant(CIRCLE(1.0), CIRCLE), variantof(RECT(1.0, 1.0)))
```

A tagged struct written by hand is registered with [`@registerVariants`](@ref); see
[Tagged structs: `@registerVariants`](@ref).

## Which one

- `@Uniontype` by default: plain structs, `isa`, and methods that dispatch on records.
- `@T_Uniontype` or `@CUniontype` for a recursive type on a hot path, where the abstract fields and containers of
  `@Uniontype` cost time and memory. `@CUniontype` when the variants extend each other, `@T_Uniontype` otherwise.
