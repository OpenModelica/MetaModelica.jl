""""
  Copyright 2019-CurrentYear: Open Source Modelica Consortium (OSMC)
  Copyright 2018: RelationalAI, Inc.

  Licensed under the Apache License, Version 2.0 (the "License"); you may
  not use this file except in compliance with the License.
  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  The code is originally based on https://github.com/RelationalAI-oss/Rematch.jl with
  changes to allow keyword argument matching on structs along with
  matching on the immutable list construct accompanying MetaModelica + some other improvements and bug fixes.
  It also provides  @matchcontinue macro (try the next case when any exception is thrown).
"""

include("fixLines.jl")

const DOC_STR = "Patterns:

    * `_` matches anything

    * `foo` matches anything, binds value to `foo`

    * `foo(__)` wildcard match on all subfields of foo, binds value to `foo`

    * `Foo(x,y,z)` matches structs of type `Foo` with fields matching `x,y,z`

    * `Foo(x=y)` matches structs of type `Foo` with a field named `x` matching `y`

    * `[x,y,z]` matches `AbstractArray`s with 3 entries matching `x,y,z`

    * `(x,y,z)` matches `Tuple`s with 3 entries matching `x,y,z`

    * `[x,y...,z]` matches `AbstractArray`s where `x` matches the first entry, `z` matches the last entry and `y` matches the remaining entries.

    * `[x,y...]` matches `AbstractArray`s , where `x` matches the first entry, and `y` matches the remaining entries.

    * `(x,y...,z)` matches `Tuple`s with at least 2 entries, where `x` matches the first entry, `z` matches the last entry and `y` matches the remaining entries.

    * `_::T` matches any subtype (`isa`) of T

    * `x || y` matches values which match either `x` or `y` (only variables which exist in both branches will be bound)

    * `x && y` matches values which match both `x` and `y`

    * `x where condition` matches only if `condition` is true (`condition` may use any variables that occur earlier in the pattern eg `(x, y, z where x + y > z)`)

    * `x <| y` is syntactic sugar for `cons(x,y)` (See the ImmutableList package)

    * Anything else is treated as a constant and tested for equality

  Patterns can be nested arbitrarily.

  Repeated variables only match if they are `==` eg `(x,x)` matches `(1,1)` but not `(1,2)`."

"""
```
@splice(iterator, body)
```

Utility macro given a body on the format
@splice <tuple> in <collection> <body>
Generates:
```
Expr(:..., :((\$(esc(body)) for \$(esc(iterator.args[2])) in \$(esc(iterator.args[3])))))
```

Example:

```
bound = [:x, :y, :z]
julia> quote \$(MetaModelica.@splice variable in bound :(
            \$(esc(variable)) = \$(Symbol("variable_\$variable"))
          )) end

quote
    #= REPL[32]:1 =#
    $(Expr(:escape, :x)) = variable_x
    $(Expr(:escape, :y)) = variable_y
    $(Expr(:escape, :z)) = variable_z
end
```
"""
macro splice(iterator, body)
  @assert iterator.head === :call
  @assert iterator.args[1] === :in
  Expr(:..., :(($(esc(body)) for $(esc(iterator.args[2])) in $(esc(iterator.args[3])))))
end

#=
TODO: make this as a mutable struct and change the msg and value instead
Should have some impact on the exception heavy control flow used in the frontend.
=#
struct MatchFailure <: MetaModelicaException
  msg::String
  value::Any
end

"""
  Statically get the fieldcount of a type. Useful to avoid runtime calls to
  fieldcount.
"""
@generated function evaluated_fieldcount(t::Type{T}) where {T}
  res = T !== NONE ? fieldcount(T) : 0
end

"""
  Statically get the fieldnames of a type. Useful to avoid runtime calls to
  fieldnames (which includes many allocations).
"""
@generated function evaluated_fieldnames(t::Type{T}) where {T}
  fieldnames(T)
end

"""
Experimental
"""
@generated function evaluated_fieldtypes(t::Type{T}) where {T}
  fieldtypes(T)
end

"""
  Handles the deconstruction of fields
"""
function handle_destruct_fields(value::Symbol, pattern, subpatterns, len, get::Symbol,
                                bound::Set{Symbol}, asserts::Vector{Expr}; allow_splat=true)
  # NOTE we assume `len` is cheap
  fields = []
  seen_splat = false
  for (i, subpattern) in enumerate(subpatterns)
    if (subpattern isa Expr) && (subpattern.head === :(...))
      @assert allow_splat && !seen_splat "Too many ... in pattern $pattern"
      @assert length(subpattern.args) == 1
      seen_splat = true
      push!(fields, (:($i:($len-$(length(subpatterns) - i))), subpattern.args[1]))
    elseif seen_splat
      push!(fields, (:($len - $(length(subpatterns) - i)), subpattern))
    elseif (subpattern isa Expr) && (subpattern.head === :kw)
      T_sym = Meta.quot(subpattern.args[1])
      push!(fields, (:($T_sym), subpattern.args[2]))
    else
      push!(fields, (i, subpattern))
    end
  end
  Expr(:&&, if seen_splat
         :($len >= $(length(subpatterns) - 1))
       else
         :($len == $(length(subpatterns)))
       end, @splice (i, (field, subpattern)) in enumerate(fields) quote
         $(Symbol("$(value)_$i")) = $get($value, $field)
         $(handle_destruct(Symbol("$(value)_$i"), subpattern, bound, asserts))
       end)
end

"""
Check if pattern is a nested @match or @matchcontinue macrocall.
Returns true if it is, false otherwise.
"""
function is_match_macrocall(pattern)
  if !(pattern isa Expr && pattern.head === :macrocall)
    return false
  end
  if length(pattern.args) < 1
    return false
  end
  mac = pattern.args[1]
  # Check for @match or @matchcontinue (with or without module prefix)
  if mac === Symbol("@match") || mac === Symbol("@matchcontinue")
    return true
  end
  if mac isa GlobalRef
    return mac.name === Symbol("@match") || mac.name === Symbol("@matchcontinue")
  end
  return false
end

"""
 Top level utility function.
 Handles deconstruction of patterns together with the value symbol.
"""
function handle_destruct(value::Symbol, pattern, bound::Set{Symbol}, asserts::Vector{Expr})
  if pattern === :(_)
    # wildcard
    true
  elseif is_match_macrocall(pattern)
    #=
     Nested @match or @matchcontinue in pattern position.
     Extract the inner pattern and value, then handle recursively.
     Structure: @match inner_pattern = inner_value
    args[1] is the macro name, args[2] is LineNumberNode, args[3] is the assignment
    =#
    if length(pattern.args) >= 3 &&
       pattern.args[3] isa Expr &&
       pattern.args[3].head === :(=)
      inner_assignment = pattern.args[3]
      inner_pattern = inner_assignment.args[1]
      inner_value_expr = inner_assignment.args[2]
      # Generate a unique symbol for the inner value
      inner_val_sym = Symbol("_nested_val_", hash(inner_pattern))
      # Recursively destruct the inner pattern
      inner_body = handle_destruct(inner_val_sym, inner_pattern, bound, asserts)
      quote
        $inner_val_sym = $inner_value_expr
        $inner_body
      end
    else
      # Unexpected structure, fall back to constant comparison
      quote
        $value === $pattern
      end
    end
  elseif !(pattern isa Expr || pattern isa Symbol) ||
         pattern === :nothing ||
         (@capture(pattern, _quote_macrocall) && !is_match_macrocall(pattern)) ||
         @capture(pattern, Symbol(_))
    # constant (but not a nested @match)
    # TODO do we have to be careful about QuoteNode etc?
    #Probably not //John
    quote
      $value === $pattern
    end
  elseif @capture(pattern, subpattern_Symbol)
    # variable
    # if the pattern doesn't match, we don't want to set the variable
    # so for now just set a temp variable
    our_sym = Symbol("variable_", pattern)
    if pattern in bound
      # already bound, check that this value matches
      :($our_sym == $value)
    else
      # bind
      push!(bound, pattern)
      :(
        $our_sym = $value;
        true
      )
    end
  elseif @capture(pattern, subpattern1_ || subpattern2_) ||
         (@capture(pattern, f_(subpattern1_, subpattern2_)) && f === :|)
    # disjunction
    # need to only bind variables which exist in both branches
    bound1 = copy(bound)
    bound2 = copy(bound)
    body1 = handle_destruct(value, subpattern1, bound1, asserts)
    body2 = handle_destruct(value, subpattern2, bound2, asserts)
    union!(bound, intersect(bound1, bound2))
    quote
      $body1 || $body2
    end
  elseif @capture(pattern, subpattern1_ && subpattern2_) ||
         (@capture(pattern, f_(subpattern1_, subpattern2_)) && f === :&)
    # conjunction
    body1 = handle_destruct(value, subpattern1, bound, asserts)
    body2 = handle_destruct(value, subpattern2, bound, asserts)
    quote
      $body1 && $body2
    end
  elseif @capture(pattern, _where)
    # guard
    @assert length(pattern.args) == 2
    subpattern = pattern.args[1]
    guard = pattern.args[2]
    quote
      $(handle_destruct(value, subpattern, bound, asserts)) && let $(bound...)
        # bind variables locally so they can be used in the guard
        $(@splice variable in bound quote
            $(esc(variable)) = $(Symbol("variable_", variable))
          end)
        $(esc(guard))
      end
    end
  elseif @capture(pattern, T_(subpatterns__)) #= All wild =#
    if length(subpatterns) == 1 && subpatterns[1] === :(__)
      #=
        Fields not interesting when matching against a wildcard.
        NONE() matched against a wildcard is also true
      =#
      quote
        $value isa $(esc(T))
      end
    else
      T = handleSugar(T)
      len = length(subpatterns)
      named_fields = [pat.args[1]
                      for pat in subpatterns if (pat isa Expr) && pat.head === :(kw)]
      nNamed = length(named_fields)
      @assert length(named_fields) == length(unique(named_fields)) "Pattern $pattern has duplicate named arguments: $(named_fields)"
      @assert nNamed == 0 || len == nNamed "Pattern $pattern mixes named and positional arguments"
      # struct
      if false
      elseif nNamed == 0
        push!(asserts,
              quote
                a = typeof($(esc(T)))
                #= NONE is a function. However, we treat it as a special case =#
                if $(esc(T)) !== NONE && typeof($(esc(T))) <: Function
                  func = $(esc(T))
                  file = @__FILE__
                  throw(LoadError("Attempted to match on a function at $(file)", @__LINE__,
                                  AssertionError("Incorrect match usage attempted to match on: $func")))
                end
                if !(isstructtype(typeof($(esc(T)))) || issabstracttype(typeof($(esc(T)))))
                  throw(LoadError("Attempted to match on a pattern that is not a struct at $(file)",
                                  @__LINE__,
                                  AssertionError("Incorrect match usage. Attempted to match on a pattern that is not a struct")))
                end
                pattern = $(esc(T))
                if $(esc(T)) !== NONE
                  if evaluated_fieldcount($(esc(T))) < $(esc(len))
                    error("Field count for pattern of type: $pattern is $($(esc(len))) expected $(evaluated_fieldcount($(esc(T))))")
                  end
                end
              end)
      else # Uses keyword arguments
        struct_name = gensym("$(T)_match")
        type_name = string(T)
        assertcond = true
        local missing_field
        for field in named_fields
          local tmp
          tmp = quote
            $(Meta.quot(field)) in $struct_name
          end
          missing_field = string(field)
          assertcond = Expr(:&&, tmp, assertcond)
        end
        push!(asserts, quote
                if !(let
                       $struct_name = evaluated_fieldnames($(esc(T)))
                       $assertcond
                     end)
                  local type_name = string($(esc(T)))
                  local ms = string($(esc(named_fields)))
                  local errorStr = "Pattern contains named arguments $(ms) some of which was not in the type $type_name with fields $(fieldnames($(esc(T)))) at:"
                  error(errorStr)
                end
              end)
      end
      :($value === nothing && $(esc(T)) === Nothing ||
        $value isa $(esc(T)) &&
        $(handle_destruct_fields(value, pattern, subpatterns, length(subpatterns),
                                 :getfield, bound, asserts; allow_splat=false)))
    end
  elseif @capture(pattern, (subpatterns__,)) # Tuple
    quote
      ($value isa Tuple) &&
      $(handle_destruct_fields(value, pattern, subpatterns, :(length($value)), :getindex,
                               bound, asserts; allow_splat=true))
    end
  elseif @capture(pattern, [subpatterns__]) # Array
    :(($value isa AbstractArray) &&
      $(handle_destruct_fields(value, pattern, subpatterns, :(length($value)), :getindex,
                               bound, asserts; allow_splat=true)))
  elseif @capture(pattern, subpattern_::T_) #ImmutableList
    quote
      # typeassert
      ($value isa $(esc(T))) && $(handle_destruct(value, subpattern, bound, asserts))
    end
  elseif @capture(pattern, _.__) #Sub member of a variable
    quote
      $value == $(esc(pattern))
    end
  else
    println(pattern)
    error("Unrecognized pattern syntax: $pattern")
  end
end

"""
  Handle syntactic sugar for MetaModelica mode.
  Mostly lists but also for the optional type.
  Parenthesis for these expressions are skipped
"""
function handleSugar(T)
  T = if T === :(<|)
    # Syntactic sugar cons.
    :Cons
  elseif T === :_cons
    #= This is legacy for the code generator. For match equation we need to allow this as well =#
    :Cons
  elseif T === :nil
    # Syntactic sugar for Nil
    :Nil
  elseif T === :NONE
    # Syntactic sugar for Nothing
    :Nothing
  else
    T
  end
end

"""
Handles match equations such as
@match x = 4
"""
function handle_match_eq(expr, calling_module::Module=Main)
  if @capture(expr, pattern_ = value_)
    asserts = Expr[]
    bound = Set{Symbol}()
    body = handle_destruct(:value, pattern, bound, asserts)
    quote
      $(asserts...)
      value = $(esc(value))
      __omc_match_done = false
      $body || throw(MatchFailure("no match", typeof(value)))
      $(@splice variable in bound :(
          $(esc(variable)) = $(Symbol("variable_$variable"))
        ))
      value
    end
  else
    error("Unrecognized match syntax: $expr")
  end
end


"""
Handles match equations such as
@unsafematch x = 4
"""
function unsafe_handle_match_eq(expr, calling_module::Module=Main)
  if @capture(expr, pattern_ = value_)
    asserts = Expr[]
    bound = Set{Symbol}()
    body = handle_destruct(:value, pattern, bound, asserts)
    quote
      #$(asserts...)
      value = $(esc(value))
      $body
      $(@splice variable in bound quote
          $(esc(variable)) = $(Symbol("variable_$variable"))
        end)
      value
    end
  else
    error("Unrecognized match syntax: $expr")
  end
end

"""
Handles match cases both for the matchcontinue and regular match case
calls handle_destruct. See handle_destruct for more details.
"""
function handle_match_case(value, case, tail, asserts, matchcontinue::Bool)
  if @capture(case, pattern_ => result_)
    bound = Set{Symbol}()
    body = handle_destruct(:value, pattern, bound, asserts)
    if matchcontinue
      quote
        if (!__omc_match_done) && $body
          try
            res = let $(bound...)
              # export bindings
              $(@splice variable in bound quote
                  $(esc(variable)) = $(Symbol("variable_", variable))
                end)
              $(esc(result))
            end
            __omc_match_done = true
          catch e
            #=
            We only rethrow for two kinds of exceptions currently.
            One for list, and one for generic MetaModelicaExceptions.
            (Thinking about it I think this might be a performance sink.
            TODO: Removing this? -John March 2024)
            =#
            # if isa(e, MetaModelicaException) || isa(e, ImmutableListException)
            #   println(e.msg)
            # else
            #   showerror(stderr, e, catch_backtrace())
            # end
            if !isa(e, MetaModelicaException) && !isa(e, ImmutableListException)
              if isa(e, MatchFailure)
                println("MatchFailure:" + e.msg)
              else
                showerror(stderr, e, catch_backtrace())
              end
              rethrow(e)
            end
            __omc_match_done = false
          end
        end
        $tail
      end
    else
      quote
        if (!__omc_match_done) && $body
          res = let $(bound...)
            # export bindings
            $(@splice variable in bound quote
                $(esc(variable)) = $(Symbol("variable_", variable))
              end)
            $(esc(result))
          end
          __omc_match_done = true
        end
        $tail
      end
    end
  else
    error("Unrecognized case syntax: $case")
  end
end


"""
Top level function for all match macros except for the match equation macro.
"""
function handle_match_cases(value, match::Expr; mathcontinue::Bool=false)
  tail = nothing
  if match.head != :block
    error("Unrecognized match syntax: Expected begin block $match")
  end
  line = nothing
  local neverFails = false
  cases = Expr[]
  asserts = Expr[]
  for arg in match.args
    if isa(arg, LineNumberNode)
      line = arg
      continue
    elseif isa(arg, Expr)
      push!(cases, arg)
    end
  end
  for case in reverse(cases)
    tail = handle_match_case(:value, case, tail, asserts, mathcontinue)
    if line !== nothing
      replaceLineNum(tail, @__FILE__, line)
    end
    #= If one case contains a _ we know this match never fails. =#
    pat = case.args[2]
    if pat === :_
      neverFails = true
    end
  end
  if neverFails == false || mathcontinue
    quote
      $(asserts...)
      local value = $(esc(value))
      local __omc_match_done::Bool = false
      local res
      $tail
      if !__omc_match_done
        throw(MatchFailure("unfinished match for type", typeof(value)))
      end
      res
    end
  else
    quote
      $(asserts...)
      local value = $(esc(value))
      local __omc_match_done::Bool = false
      local res
      $tail
      res
    end
  end
end

function unsafe_handle_match_cases(value, match::Expr; mathcontinue::Bool=false)
  tail = nothing
  if match.head != :block
    error("Unrecognized match syntax: Expected begin block $match")
  end
  line = nothing
  cases = Expr[]
  asserts = Expr[]
  for arg in match.args
    if isa(arg, LineNumberNode)
      line = arg
      continue
    elseif isa(arg, Expr)
      push!(cases, arg)
    end
  end
  for case in reverse(cases)
    tail = handle_match_case(:value, case, tail, asserts, mathcontinue)
    if line !== nothing
      replaceLineNum(tail, @__FILE__, line)
    end
  end
  quote
    #$(asserts...)
    local value = $(esc(value))
    local __omc_match_done::Bool = false
    local res
    $tail
    if !__omc_match_done
      value
    else
      res
    end
  end
end

"""
  @match pattern = value
  If `value` matches `pattern`, bind variables and return `value`. Otherwise, throw `MatchFailure`.
"""
macro match(expr)
  res = handle_match_eq(expr)
  replaceLineNum(res, @__FILE__, __source__)
  res
end


"""
  @match pattern = value
  If `value` matches `pattern`, bind variables and return `value`.
"""
macro unsafematch(expr)
  res = unsafe_handle_match_eq(expr)
  replaceLineNum(res, @__FILE__, __source__)
  res
end

"""
      @matchcontinue value begin
          pattern1 => result1
          pattern2 => result2
          ...
      end

  Return `result` for the first matching `pattern`. If there are no matches, throw `MatchFailure`.
"""
macro matchcontinue(value, cases)
  res = handle_match_cases(value, cases; mathcontinue=true)
  replaceLineNum(res, @__FILE__, __source__)
  res
end

"""
      @match value begin
          pattern1 => result1
          pattern2 => result2
          ...
      end

  Return `result` for the first matching `pattern`. If there are no matches, throw `MatchFailure`

"""
macro match(value, cases)
  res = handle_match_cases(value, cases; mathcontinue=false)
  replaceLineNum(res, @__FILE__, __source__)
  res
end

"""
      @unsafematch value begin
          pattern1 => result1
          pattern2 => result2
          ...
      end
  Return `result` for the first matching `pattern`. If there are no matches, returns `value`.
"""
macro unsafematch(value, cases)
  res = unsafe_handle_match_cases(value, cases; mathcontinue=false)
  replaceLineNum(res, @__FILE__, __source__)
  res
end

"""
Helper function for @fastmatch
"""
function handle_fast_match(value, arg_cases, caleeModule)
  local methods = Expr[]
  local cases = Tuple{Symbol,Union{Symbol,Expr}, Expr, Set{Symbol}, Union{Symbol, Expr, Any}}[]
  for arg in arg_cases.args
    if isa(arg, LineNumberNode)
      line = arg
      continue
    elseif isa(arg, Expr)
      capture = @capture(arg, pattern_ => rhs_)
      @assert capture "Pattern was not on the form pattern => body/expr"
      type_name = first(pattern.args)
      asserts = Expr[]
      bound = Set{Symbol}()
      destruct_body = handle_destruct(value, pattern, bound, asserts)
      push!(cases, (value, type_name, destruct_body, bound, rhs))
    end
  end
  local funcName = Symbol(string(value, "Func"))
  local i = 1
  for case in cases
    local func_name = case[1]
    local type_name = case[2]
    local dbody = case[3]
    local bound = case[4]
    local rhs = case[5]
    local fixedBody = :($dbody)
    #= HACK Fix me. Remove various redudant checks... =#
    println(fixedBody)
    #= Idea is to do some things different below depending on if we should expand our helper or not=#
    local iterate = true
    try
      fixedBody = dbody.args[2].args[2].args
    catch
      iterate = false
    end

    # local method  = :(
    #   function $(esc(funcName))($(esc(value))::$(esc(type_name)))
    #     $(esc.(fixedBody)...)
    #     $(@splice variable in bound :(
    #       $(esc(variable)) = $(esc(Symbol("variable_$variable")))
    #     ))
    #     $(esc(rhs))
    #   end)
    #= Static evaluation...=#
    T = quote T = MetaModelica.evaluated_fieldtypes($(type_name)) end
    T2 = quote
      @eval $(caleeModule)  begin
        fieldtypes($(type_name))
      end
    end
    T3 = quote
      @eval $(caleeModule)  begin
        fieldnames($(type_name))
      end
    end
    T2 = Core.eval(caleeModule, T2)
    T3 = Core.eval(caleeModule, T3)
    # T4 = (T2..., T3...)
    # println(T4)
    # bodyDest = quote
    #   $(@splice (i, variable) in enumerate(T2) :(
    #     $(fieldname(value,i)) = $(Symbol("variable_$variable"))::$(T2[i])))
    # end

    #println(T)


    #println("T2:", T2)
    #println("T3:", T3)
    #    println("bodyDest:", bodyDest)
    local method  = :(
      function $(funcName)($(value)::$(type_name))
        $(fixedBody...)
        $(@splice (i, variable) in enumerate(bound) :(
          $variable =$(Symbol("variable_$variable"))::$(T2[i])
        ))
        $rhs
      end)
    #push!(methods,method)
    println(method)
    #= Define the function as a global function in the scope of the caller =#
    Core.eval(caleeModule, MacroTools.flatten(method))
    i += 1
  end
  res = quote
      $(Expr(:block, methods...))
    #= TODO: guarding statements etc can be constructed here later... =#
      @inline($(esc(funcName))($(esc(value))))
  end
  res = MacroTools.flatten(res)
  MacroTools.postwalk(res) do x
    MacroTools.flatten(x)
  end
end

"""
Similar to match but more limited.
Instead of handling everything within one function we generate a new function for each case.
Hence, we limit the possible objects we can match on to structs.

Here we generate a function for each type with <function_name>
Example:


```
@fastmatch <type-we-match-on> begin
             FOO(v) => v
             BAR(l, r) => l + r
             FOOO() => v
           end
```
This will result in the generation of the following functions:

```
function <type-we-match-on>Func(case::FOO)
  Foo.v
end

function <type-we-match-on>Func(case::BAR)
  l + r
end

function <type-we-match-on>Func(case::FOOO)
   v
end
```

"""
macro fastmatch(value, cases)
  res = handle_fast_match(value, cases, __module__)
  replaceLineNum(res, @__FILE__, __source__)
  res
end

export @fastmatch

"""
$DOC_STR
"""
:(@matchcontinue)

"""
$DOC_STR
"""
:(@match)

"""
Patterns:

* ```FOO(a,b)```

* ```BAR()```

When using @fastmatch we limit the usage and only allow match on structs.

Here, the use variables that are not bound to the structs will result in errors, therefore, use this match option carefully.
"""
:(@fastmatch)
