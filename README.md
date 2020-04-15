# MetaModelica.jl [![License: OSMC-PL](https://img.shields.io/badge/license-OSMC--PL-lightgrey.svg)](OSMC-License.txt)

This package replicates the runtime of the programming language MetaModelica. It also exposes
other packages that are a part of this runtime such as ImmutableList.jl

MetaModelica supports a powerfull but expensive mechanism for pattern matching called matchcontinue
This is provided by an extension of Rematch.jl

# Style
This package follows [YASGuide](https://github.com/jrevels/YASGuide).
Adherence to the standard will be checked during CI.

# Pattern Matching and Patterns:

    * `_` matches anything
    * `foo` matches anything, binds value to `foo`
    * `foo(__)` wildcard match on all subfields of foo, binds value to `foo`
    * `Foo(x,y,z)` matches structs of type `Foo` with fields matching `x,y,z`
    * `Foo(x=y)` matches structs of type `Foo` with a field named `x` matching `y`
    * `[x,y,z]` matches `AbstractArray`s with 3 entries matching `x,y,z`
    * `(x,y,z)` matches `Tuple`s with 3 entries matching `x,y,z`
    * `[x,y...,z]` matches `AbstractArray`s with at least 2 entries, where `x` matches the first entry, `z` matches the last entry and `y` matches the remaining entries.
    * `(x,y...,z)` matches `Tuple`s with at least 2 entries, where `x` matches the first entry, `z` matches the last entry and `y` matches the remaining entries.
    * `_::T` matches any subtype (`isa`) of T
    * `x || y` matches values which match either `x` or `y` (only variables which exist in both branches will be bound)
    * `x && y` matches values which match both `x` and `y`
    * `x where condition` matches only if `condition` is true (`condition` may use any variables that occur earlier in the pattern eg `(x, y, z where x + y > z)`)
    * Anything else is treated as a constant and tested for equality

* Patterns can be nested arbitrarily.

* Pattern matching is also possible on the list implementation provided by ImmutableList.jl:

  `H <| T matches the head to H and the tail to T for a given input list `
  
  `_ <| T matches a wildcard head and the tail to T for a given input list `
  
  `nil() or list() matches the empty list`


* Repeated variables only match if they are equal: 
eg `(x,x)` matches `(1,1)` but not `(1,2)`.

# @shouldFail

`@shouldFail(arg)` Is a special construct of MetaModelica.
 It succeeds if arg fails, where arg is a local match-equation/statement.
 
 # Optional
 An optional datatype 
 SOME(X), NONE(). Works in match statements
