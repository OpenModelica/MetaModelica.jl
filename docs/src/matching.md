```@meta
CurrentModule = MetaModelica
```

# Pattern matching

MetaModelica.jl has two match macros. Both try the cases in order and return the result of the first
case that matches.

|                          | [`@match`](@ref)                | [`@matchcontinue`](@ref)                                      |
|--------------------------|---------------------------------|---------------------------------------------------------------|
| Case taken               | first pattern that matches      | first pattern that matches and whose result does not fail     |
| Result expression fails  | the failure propagates          | the next case is tried                                        |
| No case left             | throws `MatchFailure`   | throws `MatchFailure`                                 |
| Cost per case            | type checks and field loads     | the same, plus a `try`/`catch`                                |

Use `@match` unless a case can only be rejected by running its result expression.

## The example types

The examples on this page use this uniontype:

```@example match
using MetaModelica

@Uniontype Exp begin
  @Record INT begin
    value::Int
  end
  @Record ADD begin
    lhs::Exp
    rhs::Exp
  end
  @Record NEG begin
    exp::Exp
  end
end
nothing # hide
```

## `@match value begin ... end`

Each case is `pattern => result`. The variables a pattern binds are local to the case's result.

```@example match
function evaluate(e::Exp)::Int
  @match e begin
    INT(v) => v
    ADD(l, r) => evaluate(l) + evaluate(r)
    NEG(x) => -evaluate(x)
  end
end

evaluate(ADD(INT(1), NEG(INT(3))))
```

When the subject is a variable, `@match` narrows its type in each case's result. In `ADD(__) => e.lhs`, `e` is
known to be an `ADD`, so the field access is type-stable.

```@example match
lhsOrSelf(e::Exp)::Exp = @match e begin
  ADD(__) => e.lhs
  _ => e
end

lhsOrSelf(ADD(INT(7), INT(1)))
```

A value that no case matches throws `MatchFailure`. End with a `_ => ...` case to give a default.

## Patterns

| Pattern                    | Matches                                                                                |
|----------------------------|----------------------------------------------------------------------------------------|
| `_`                        | anything; binds nothing                                                                |
| `x`                        | anything; binds `x` (a name used twice in a pattern must match equal values)           |
| `1`, `"a"`, `:s`, `nothing`| a value `===` to the literal                                                           |
| `C`                        | the value of `C`, if `C` is a `const` `Integer`, float, `Bool` or `Char` of the module |
| `REC(p1, p2)`              | a `REC` whose first fields match `p1`, `p2` in order                                   |
| `REC(field = p)`           | a `REC` whose named fields match; other fields are not checked                         |
| `REC(__)`                  | any `REC`                                                                              |
| `h <| t`                   | a non-empty list with head `h` and tail `t`                                            |
| `nil()`                    | the empty list. Write `nil()`: a bare `nil` is a variable that binds anything          |
| `SOME(p)`, `NONE()`        | an [`Option`](@ref) holding a value that matches `p`; no value                         |
| `(p1, p2)`                 | a tuple of that length                                                                 |
| `[p1, p2]`, `[p1, rest...]`| an array of that length; one `...` takes the remaining elements                        |
| `p::T`                     | a value of type `T` that matches `p`                                                   |
| `p1 || p2`                 | `p1` or `p2`; only the variables bound in both are bound                               |
| `p1 && p2`                 | `p1` and `p2`                                                                          |
| `p where cond`             | `p`, if `cond` (which may use `p`'s variables) is true. Write `p where (a && b)`: without the parentheses the `&&` joins patterns |

Patterns nest:

```@example match
function firstPositive(lst::List{Int})::Int
  @match lst begin
    x <| _ where x > 0 => x
    _ <| rest => firstPositive(rest)
    nil() => 0
  end
end

firstPositive(list(-1, 0, 5, 3))
```

```@example match
either(t::Tuple{Int, Int})::Int = @match t begin
  (a, 1) || (1, a) => a
  _ => 0
end

(either((5, 1)), either((1, 6)), either((2, 2)))
```

```@example match
simplify(e::Exp)::Exp = @match e begin
  NEG(NEG(x)) => x
  ADD(INT(0), x) || ADD(x, INT(0)) => x
  ADD(lhs = INT(a), rhs = INT(b)) => INT(a + b)
  _ => e
end

(simplify(NEG(NEG(INT(4)))), simplify(ADD(INT(0), NEG(INT(1)))), simplify(ADD(INT(2), INT(3))))
```

## `@match pattern = value`

The match equation of MetaModelica: it binds the pattern's variables in the enclosing scope and returns the
value. A value that does not match throws `MatchFailure`.

```@example match
@match ADD(INT(a), INT(b)) = ADD(INT(1), INT(2))
a + b
```

## Matching your own types

### Plain structs

Any Julia struct matches without registration. The name is the type; positional patterns follow the field order,
named patterns the field names.

```@example match
struct Point
  x::Float64
  y::Float64
end

quadrant(p::Point)::Int = @match p begin
  Point(0.0, 0.0) => 0
  Point(x = x, y = y) where (x > 0 && y > 0) => 1
  Point(__) => -1
end

quadrant.([Point(0, 0), Point(1, 2), Point(-1, 2)])
```

`@Uniontype` with `@Record` (above) gives one struct per record, so a record matches the same way.

### Tagged structs: `@registerVariants`

A tagged struct is one concrete type for all variants, with a `tag` field that says which variant a value is.
`@T_Uniontype` and `@CUniontype` generate such a struct together with its variants. For a struct written by hand,
[`@registerVariants`](@ref) adds what `@match`, `isvariant` and `variantof` need:

- a `tag` field holding an `@enum` with one value per variant, named `<VARIANT>_TAG`, in the order of the
  variants (the first is 0);
- per variant a constructor function returning a value with that tag, defined before `@registerVariants`;
- per variant the fields its pattern binds, in the order of its positional arguments.

```@example match
@enum ShapeTag::UInt8 CIRCLE_TAG RECT_TAG

struct Shape
  tag::ShapeTag
  r::Float64
  w::Float64
  h::Float64
end
CIRCLE(r) = Shape(CIRCLE_TAG, r, 0.0, 0.0)
RECT(w, h) = Shape(RECT_TAG, 0.0, w, h)

@registerVariants Shape begin
  CIRCLE(r)
  RECT(w, h)
end

area(s::Shape)::Float64 = @match s begin
  CIRCLE(r) => pi * r^2
  RECT(w, h) => w * h
end

(area(CIRCLE(1.0)), area(RECT(2.0, 3.0)), isvariant(RECT(1.0, 1.0), RECT))
```

The variant name in a pattern is the constructor function, not a type: `CIRCLE(r)` matches a `Shape` whose tag is
`CIRCLE_TAG` and binds its field `r`. An `@enum` in another order than the variant list is an error when
`@registerVariants` runs, not a wrong match.

## `@matchcontinue`

`@matchcontinue` has the syntax of `@match`. A case whose result fails sends the match on to the next case.
A failure is a `MetaModelicaException` or an
`ImmutableListException`:

- `fail()`, and the builtins that fail on bad input (`stringInt("2.5")`, `listHead(nil)`, ...);
- a `MatchFailure`: an inner `@match` with no matching case, or a match equation that does not match.

Any other exception (`BoundsError`, `MethodError`, ...) is a bug, not a failure: `@matchcontinue` prints it and
rethrows it.

```@example match
function describe(s::String)::String
  @matchcontinue s begin
    _ => "integer " * intString(stringInt(s))
    _ => "real " * realString(stringReal(s))
    _ => "text"
  end
end

describe.(["42", "2.5", "x"])
```

A match equation in a case states what the case needs. When it does not hold, the case fails and the next
case runs:

```@example match
function addInts(e::Exp)::Int
  @matchcontinue e begin
    _ => begin
      @match ADD(INT(a), INT(b)) = e
      a + b
    end
    _ => 0
  end
end

(addInts(ADD(INT(1), INT(2))), addInts(NEG(INT(1))))
```

A failed case is not undone: what it changed before it failed (an array, a dictionary, a global root) stays
changed.

### `@match` or `@matchcontinue`

- If a pattern can decide, use `@match` with a pattern or a `where` guard. `@match` checks patterns without
  exceptions.
- Use `@matchcontinue` when only the result can decide, as in `describe` above. Each failed case costs a thrown
  exception, much more than a pattern that does not match.
- A `@matchcontinue` whose cases never fail is a `@match` with the cost of the `try`/`catch`.

## Debugging `@matchcontinue`: `MM_Debug`

`MetaModelica.MM_Debug` has a `@matchcontinue` that logs each failure it swallows. Swap it in with one import;
the explicit import wins over `using MetaModelica`:

```julia
using MetaModelica
using MetaModelica.MM_Debug: @matchcontinue

MetaModelica.MM_Debug.clear!()
# ... run the code ...
MetaModelica.MM_Debug.summarize()   # failures per exception type
MetaModelica.MM_Debug.print_log()   # the last entries: case number, exception, source line
```

Remove the import to return to the plain macro.
