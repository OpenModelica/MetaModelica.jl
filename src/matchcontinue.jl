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

macro splice(iterator, body)
  @assert iterator.head === :call
  @assert iterator.args[1] === :in
  Expr(:..., :(($(esc(body)) for $(esc(iterator.args[2])) in $(esc(iterator.args[3])))))
end

struct MatchFailure <: MetaModelicaException
  msg::Any
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
 Top level utility function.
 Handles deconstruction of patterns together with the value symbol.
"""
function handle_destruct(value::Symbol, pattern, bound::Set{Symbol}, asserts::Vector{Expr})
  if pattern === :(_)
    # wildcard
    true
  elseif !(pattern isa Expr || pattern isa Symbol) ||
         pattern === :nothing ||
         @capture(pattern, _quote_macrocall) ||
         @capture(pattern, Symbol(_))
    # constant
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
      quote
        $our_sym == $value
      end
    else
      # bind
      push!(bound, pattern)
      quote
        $our_sym = $value
        true
      end
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
        for field in named_fields
          local tmp
          tmp = quote
            $(Meta.quot(field)) in $struct_name
          end
          assertcond = Expr(:&&, tmp, assertcond)
        end
        push!(asserts, quote
                if !(let
                       $struct_name = evaluated_fieldnames($(esc(T)))
                       $assertcond
                     end)
                  error("Pattern contains named argument not in the type at: ")
                end
              end)
      end
      quote
        $value === nothing && $(esc(T)) === Nothing ||
        $value isa $(esc(T)) &&
        $(handle_destruct_fields(value, pattern, subpatterns, length(subpatterns),
                                 :getfield, bound, asserts; allow_splat=false))
      end
    end
  elseif @capture(pattern, (subpatterns__,)) # Tuple
    quote
      ($value isa Tuple) &&
      $(handle_destruct_fields(value, pattern, subpatterns, :(length($value)), :getindex,
                               bound, asserts; allow_splat=true))
    end
  elseif @capture(pattern, [subpatterns__]) # Array
    quote
      ($value isa AbstractArray) &&
      $(handle_destruct_fields(value, pattern, subpatterns, :(length($value)), :getindex,
                               bound, asserts; allow_splat=true))
    end
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
function handle_match_eq(expr)
  if @capture(expr, pattern_ = value_)
    asserts = Expr[]
    bound = Set{Symbol}()
    body = handle_destruct(:value, pattern, bound, asserts)
    quote
      $(asserts...)
      value = $(esc(value))
      __omc_match_done = false
      $body || throw(MatchFailure("no match", value))
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
            =#
            #if isa(e, MetaModelicaException) || isa(e, ImmutableListException)
            #  println(e.msg)
            #else
            #  showerror(stderr, e, catch_backtrace())
            #end
            filterMetaModelicaExceptionAndThrow(e)
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
        throw(MatchFailure("unfinished", value))
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
    $(asserts...)
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

  Return `result` for the first matching `pattern`. If there are no matches, throw `MatchFailure`.
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
  Patterns:

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
    * `x => y` is syntactic sugar for `cons(x,y)` [Preliminary]
    * Anything else is treated as a constant and tested for equality

  Patterns can be nested arbitrarily.

  Repeated variables only match if they are `==` eg `(x,x)` matches `(1,1)` but not `(1,2)`.
  """
:(@matchcontinue)
