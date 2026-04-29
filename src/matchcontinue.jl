"""
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
TODO: Consider making MatchFailure mutable and updating msg/value in place
to reduce allocations in exception-heavy frontend control flow.
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
                                bound::Set{Symbol}, asserts::Vector{Expr}; allow_splat=true, calling_module::Union{Module,Nothing}=nothing, source::Union{LineNumberNode,Nothing}=nothing)
  #= NOTE: Assumes `len` is cheap. =#
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
         $(handle_destruct(Symbol("$(value)_$i"), subpattern, bound, asserts; calling_module=calling_module, source=source))
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
  #= Check for @match or @matchcontinue, with or without module prefix. =#
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
function handle_destruct(value::Symbol, pattern, bound::Set{Symbol}, asserts::Vector{Expr}; calling_module::Union{Module,Nothing}=nothing, source::Union{LineNumberNode,Nothing}=nothing)
  if pattern === :(_)
    #= Wildcard. =#
    true
  elseif is_match_macrocall(pattern)
    #=
    Nested @match or @matchcontinue in pattern position.
    Extract the inner pattern and value, then handle recursively.
    Structure: @match inner_pattern = inner_value.
    args[1] is the macro name, args[2] is LineNumberNode, args[3] is the assignment.
    =#
    if length(pattern.args) >= 3 &&
       pattern.args[3] isa Expr &&
       pattern.args[3].head === :(=)
      inner_assignment = pattern.args[3]
      inner_pattern = inner_assignment.args[1]
      inner_value_expr = inner_assignment.args[2]
      #= Generate a unique symbol for the inner value. =#
      inner_val_sym = Symbol("_nested_val_", hash(inner_pattern))
      #= Recursively destruct the inner pattern. =#
      inner_body = handle_destruct(inner_val_sym, inner_pattern, bound, asserts; calling_module=calling_module, source=source)
      quote
        $inner_val_sym = $inner_value_expr
        $inner_body
      end
    else
      #= Unexpected structure, fall back to constant comparison. =#
      quote
        $value === $pattern
      end
    end
  elseif !(pattern isa Expr || pattern isa Symbol) ||
         pattern === :nothing ||
         (@capture(pattern, _quote_macrocall) && !is_match_macrocall(pattern)) ||
         @capture(pattern, Symbol(_))
    #= Constant, but not a nested @match.
       TODO: Check whether QuoteNode needs special handling. =#
    quote
      $value === $pattern
    end
  elseif @capture(pattern, subpattern_Symbol)
    #= Treat simple constants in the calling module as value comparisons rather
       than variable bindings. This is needed for enum-to-Int constants
       (Op_ADD, Variability_CONSTANT, etc.). Limit this to simple value types
       to avoid capturing Base function/type names that happen to be const. =#
    if calling_module !== nothing &&
       isdefined(calling_module, pattern) &&
       isconst(calling_module, pattern) &&
       let val = getfield(calling_module, pattern)
         val isa Union{Integer, AbstractFloat, Bool, Char}
       end
      quote
        $value === $(esc(pattern))
      end
    else
      #= Bind through a temporary variable so failed patterns do not leak bindings. =#
      our_sym = Symbol("variable_", pattern)
      if pattern in bound
        #= Already bound; check that this value matches. =#
        :($our_sym == $value)
      else
        #= Bind. =#
        push!(bound, pattern)
        :(
          $our_sym = $value;
          true
        )
      end
    end
  elseif @capture(pattern, subpattern1_ || subpattern2_) ||
         (@capture(pattern, f_(subpattern1_, subpattern2_)) && f === :|)
    #= Disjunction: only bind variables present in both branches. =#
    bound1 = copy(bound)
    bound2 = copy(bound)
    body1 = handle_destruct(value, subpattern1, bound1, asserts; calling_module=calling_module, source=source)
    body2 = handle_destruct(value, subpattern2, bound2, asserts; calling_module=calling_module, source=source)
    union!(bound, intersect(bound1, bound2))
    quote
      $body1 || $body2
    end
  elseif @capture(pattern, subpattern1_ && subpattern2_) ||
         (@capture(pattern, f_(subpattern1_, subpattern2_)) && f === :&)
    #= Conjunction. =#
    body1 = handle_destruct(value, subpattern1, bound, asserts; calling_module=calling_module, source=source)
    body2 = handle_destruct(value, subpattern2, bound, asserts; calling_module=calling_module, source=source)
    quote
      $body1 && $body2
    end
  elseif @capture(pattern, _where)
    #= Guard. =#
    @assert length(pattern.args) == 2
    subpattern = pattern.args[1]
    guard = pattern.args[2]
    quote
      $(handle_destruct(value, subpattern, bound, asserts; calling_module=calling_module, source=source)) && let $(bound...)
        #= Bind variables locally so they can be used in the guard. =#
        $(@splice variable in bound quote
            $(esc(variable)) = $(Symbol("variable_", variable))
          end)
        $(esc(guard))
      end
    end
  elseif @capture(pattern, T_(subpatterns__)) #= All-wild struct pattern. =#
    if length(subpatterns) == 1 && subpatterns[1] === :(__)
      #=
      Fields are irrelevant when matching against a wildcard.
      NONE() also matches a wildcard.
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
      #= Struct pattern. =#
      #= Try to resolve T at expansion time so structural checks fire here =#
      #= rather than at first call. Falls back to runtime asserts when the =#
      #= type is not yet defined (forward reference / unimported module). =#
      local Tval = calling_module === nothing ? nothing : MatchUtil.try_resolve_type(T, calling_module)
      local staticOK = Tval !== nothing && Tval !== NONE && MatchUtil._isStaticallyKnown(Tval)
      if false
      elseif nNamed == 0
        if staticOK
          MatchUtil.check_pattern_arity(Tval, len;
                                        macro_name="@match",
                                        type_label=string(T),
                                        source=source)
        else
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
        end
      else #= Uses keyword arguments. =#
        if staticOK
          MatchUtil.check_pattern_named_fields(Tval, Vector{Symbol}(named_fields);
                                               macro_name="@match",
                                               type_label=string(T),
                                               source=source)
        else
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
      end
      :($value === nothing && $(esc(T)) === Nothing ||
        $value isa $(esc(T)) &&
        $(handle_destruct_fields(value, pattern, subpatterns, length(subpatterns),
                                 :getfield, bound, asserts; allow_splat=false, calling_module=calling_module, source=source)))
    end
  elseif @capture(pattern, (subpatterns__,)) #= Tuple. =#
    quote
      ($value isa Tuple) &&
      $(handle_destruct_fields(value, pattern, subpatterns, :(length($value)), :getindex,
                               bound, asserts; allow_splat=true, calling_module=calling_module, source=source))
    end
  elseif @capture(pattern, [subpatterns__]) #= Array. =#
    :(($value isa AbstractArray) &&
      $(handle_destruct_fields(value, pattern, subpatterns, :(length($value)), :getindex,
                               bound, asserts; allow_splat=true, calling_module=calling_module, source=source)))
  elseif @capture(pattern, subpattern_::T_) #= ImmutableList. =#
    quote
      #= Type assertion. =#
      ($value isa $(esc(T))) && $(handle_destruct(value, subpattern, bound, asserts; calling_module=calling_module, source=source))
    end
  elseif @capture(pattern, _.__) #= Sub-member of a variable. =#
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
    #= Syntactic sugar for Cons. =#
    :Cons
  elseif T === :_cons
    #= Legacy code-generator spelling; match equations must allow this too. =#
    :Cons
  elseif T === :nil
    #= Syntactic sugar for Nil. =#
    :Nil
  elseif T === :NONE
    #= Syntactic sugar for Nothing. =#
    :Nothing
  else
    T
  end
end

"""
Handles match equations such as
@match x = 4
"""
function handle_match_eq(expr; calling_module::Module=Main, source::Union{LineNumberNode,Nothing}=nothing)
  if @capture(expr, pattern_ = value_)
    asserts = Expr[]
    bound = Set{Symbol}()
    body = handle_destruct(:value, pattern, bound, asserts; calling_module=calling_module, source=source)
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
function unsafe_handle_match_eq(expr; calling_module::Module=Main, source::Union{LineNumberNode,Nothing}=nothing)
  if @capture(expr, pattern_ = value_)
    asserts = Expr[]
    bound = Set{Symbol}()
    body = handle_destruct(:value, pattern, bound, asserts; calling_module=calling_module, source=source)
    quote
      #= Skip assertion checks in unsafe matches. =#
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
function handle_match_case(value, case, tail, asserts, matchcontinue::Bool; calling_module::Union{Module,Nothing}=nothing, source::Union{LineNumberNode,Nothing}=nothing)
  if @capture(case, pattern_ => result_)
    bound = Set{Symbol}()
    body = handle_destruct(:value, pattern, bound, asserts; calling_module=calling_module, source=source)
    if matchcontinue
      quote
        if (!__omc_match_done) && $body
          try
            res = let $(bound...)
              #= Export bindings. =#
              $(@splice variable in bound quote
                  $(esc(variable)) = $(Symbol("variable_", variable))
                end)
              $(esc(result))
            end
            __omc_match_done = true
          catch e
            #=
            matchcontinue retries later cases for MetaModelica and ImmutableList
            failures. Unexpected exceptions are printed and rethrown.
            John, March 2024: this may be a performance sink.
            =#
            if !isa(e, MetaModelicaException) && !isa(e, ImmutableListException)
              if isa(e, MatchFailure)
                println("MatchFailure:" * e.msg)
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
            #= Export bindings. =#
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
function handle_match_cases(value, match::Expr; matchcontinue::Bool=false, calling_module::Union{Module,Nothing}=nothing, source::Union{LineNumberNode,Nothing}=nothing)
  tail = nothing
  if match.head != :block
    error("Unrecognized match syntax: Expected begin block $match")
  end
  line = nothing
  local matchNeverFails = false
  cases = Expr[]
  caseSources = Union{LineNumberNode,Nothing}[]
  asserts = Expr[]
  local curLine::Union{LineNumberNode,Nothing} = source
  for arg in match.args
    if isa(arg, LineNumberNode)
      line = arg
      curLine = arg
      continue
    elseif isa(arg, Expr)
      push!(cases, arg)
      push!(caseSources, curLine)
    end
  end
  local macroName = matchcontinue ? "@matchcontinue" : "@match"
  MatchUtil.check_empty_cases(cases; macro_name=macroName, value=value, source=source)
  if !matchcontinue
    MatchUtil.check_unreachable_after_wildcard(cases; macro_name=macroName, value=value, source=source)
  end
  for i in length(cases):-1:1
    case = cases[i]
    tail = handle_match_case(:value, case, tail, asserts, matchcontinue; calling_module=calling_module, source=caseSources[i])
    if line !== nothing
      replaceLineNum(tail, @__FILE__, line)
    end
    #= A wildcard case means the match cannot fail. =#
    pat = case.args[2]
    if pat === :_
      matchNeverFails = true
    end
  end
  if matchNeverFails == false || matchcontinue
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

function unsafe_handle_match_cases(value, match::Expr; matchcontinue::Bool=false, calling_module::Union{Module,Nothing}=nothing, source::Union{LineNumberNode,Nothing}=nothing)
  tail = nothing
  if match.head != :block
    error("Unrecognized match syntax: Expected begin block $match")
  end
  line = nothing
  cases = Expr[]
  caseSources = Union{LineNumberNode,Nothing}[]
  asserts = Expr[]
  local curLine::Union{LineNumberNode,Nothing} = source
  for arg in match.args
    if isa(arg, LineNumberNode)
      line = arg
      curLine = arg
      continue
    elseif isa(arg, Expr)
      push!(cases, arg)
      push!(caseSources, curLine)
    end
  end
  for i in length(cases):-1:1
    case = cases[i]
    tail = handle_match_case(:value, case, tail, asserts, matchcontinue; calling_module=calling_module, source=caseSources[i])
    if line !== nothing
      replaceLineNum(tail, @__FILE__, line)
    end
  end
  quote
    #= Skip assertion checks in unsafe matches. =#
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
  res = handle_match_eq(expr; calling_module=__module__, source=__source__)
  replaceLineNum(res, @__FILE__, __source__)
  res
end


"""
  @match pattern = value
  If `value` matches `pattern`, bind variables and return `value`.
"""
macro unsafematch(expr)
  res = unsafe_handle_match_eq(expr; calling_module=__module__, source=__source__)
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
  res = handle_match_cases(value, cases; matchcontinue=true, calling_module=__module__, source=__source__)
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
  res = handle_match_cases(value, cases; matchcontinue=false, calling_module=__module__, source=__source__)
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
  res = unsafe_handle_match_cases(value, cases; matchcontinue=false, calling_module=__module__)
  replaceLineNum(res, @__FILE__, __source__)
  res
end

"""
Helper function for @fastmatch.

Strategy. For each case `T(p1, p2, ...) => rhs`, generate a Julia method
`<value>Func(<value>::T)` that destructures `<value>` into the named bindings
and evaluates `rhs`. Dispatch among the cases happens via Julia's
multiple-dispatch on the runtime type of `<value>`.

Supported pattern shapes inside the struct call:
  * positional Symbol bindings, e.g. `T(x, y)` binds `x = obj.field1`,
    `y = obj.field2` using `fieldnames(T)` order.
  * `_` and `__` placeholders skip the corresponding field.
  * keyword bindings `field=name` bind `name = obj.field`.

Unsupported shapes raise at macro-expansion time (literal patterns, nested
patterns, `where` guards). Two cases dispatched on the same struct type
overwrite the same generated method.
"""
function handle_fast_match(value, arg_cases, caleeModule, source::Union{LineNumberNode,Nothing}=nothing)
  local loc = source === nothing ? "" : "$(source.file):$(source.line): "

  if !(isa(arg_cases, Expr) && arg_cases.head === :block)
    error(loc * "@fastmatch: expected a `begin ... end` block of cases, got $(arg_cases)")
  end
  if !isa(value, Symbol)
    error(loc * "@fastmatch: matched value must be a plain Symbol, got $(value)")
  end

  local funcName  = Symbol(string(value, "Func"))
  local seenTypes = Symbol[]
  local caseLine  = source

  for arg in arg_cases.args
    if isa(arg, LineNumberNode)
      caseLine = arg
      continue
    end
    local caseLoc = "$(caseLine.file):$(caseLine.line): "
    if !(isa(arg, Expr) && arg.head === :call && length(arg.args) == 3 && arg.args[1] === :(=>))
      error(caseLoc * "@fastmatch: each case must be `pattern => result`, got $(arg)")
    end
    local pattern = arg.args[2]
    local rhs     = arg.args[3]

    if !(isa(pattern, Expr) && pattern.head === :call && !isempty(pattern.args))
      error(caseLoc * "@fastmatch: pattern must be a struct constructor `T(...)`, got $(pattern)")
    end
    local type_sym = pattern.args[1]
    if !isa(type_sym, Symbol)
      error(caseLoc * "@fastmatch: struct head must be a plain Symbol, got $(type_sym)")
    end
    MatchUtil.check_duplicate_case_head!(seenTypes, type_sym;
                                         macro_name="@fastmatch",
                                         value=value,
                                         source=caseLine,
                                         strictness=:error)
    local pat_args = @view pattern.args[2:end]

    local fnames
    try
      fnames = Core.eval(caleeModule, :(fieldnames($(type_sym))))
    catch err
      error(caseLoc * "@fastmatch: cannot resolve fieldnames($(type_sym)) in $(caleeModule): $(err)")
    end

    local bindings = Expr[]
    if !(length(pat_args) == 1 && pat_args[1] === :__)
      for (i, pa) in enumerate(pat_args)
        if pa === :_ || pa === :__
          continue
        elseif isa(pa, Symbol)
          if i > length(fnames)
            error(caseLoc * "@fastmatch: too many positional patterns for $(type_sym) (struct has $(length(fnames)) fields)")
          end
          local field = fnames[i]
          push!(bindings, :($(pa) = Base.getfield($(value), $(QuoteNode(field)))))
        elseif isa(pa, Expr) && pa.head === :kw && isa(pa.args[1], Symbol)
          local field = pa.args[1]
          if !(field in fnames)
            error(caseLoc * "@fastmatch: `$(field)` is not a field of $(type_sym). Fields: $(fnames)")
          end
          local sub = pa.args[2]
          if isa(sub, Symbol) && sub !== :_
            push!(bindings, :($(sub) = Base.getfield($(value), $(QuoteNode(field)))))
          elseif isa(sub, Symbol) && sub === :_
            #= explicit wildcard via keyword: skip =#
          else
            error(caseLoc * "@fastmatch: keyword binding `$(pa)` in $(type_sym)(...) must be `field=name`")
          end
        else
          error(caseLoc * "@fastmatch: unsupported pattern element `$(pa)` in $(type_sym)(...). Only positional Symbol bindings, `_`, `__`, and `field=name` are allowed")
        end
      end
    end

    local method_def = :(
      @inline function $(funcName)($(value)::$(type_sym))
        $(bindings...)
        $(rhs)
      end
    )
    Core.eval(caleeModule, MacroTools.flatten(method_def))
  end

  MatchUtil.check_return_type_uniformity(funcName, seenTypes, caleeModule;
                                         macro_name="@fastmatch",
                                         value=value,
                                         source=source,
                                         strictness=:error)

  return :(@inline $(esc(funcName))($(esc(value))))
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
  res = handle_fast_match(value, cases, __module__, __source__)
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
