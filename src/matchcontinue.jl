"""
Copyright 2018: Open Source Modelica Consortium (OSMC)
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

The code is based on https://github.com/RelationalAI-oss/Rematch.jl with
changed to allow keyword argument matching on a struct as well as
supporting @matchcontinue (try the next case when any exception is thrown).
"""

import MacroTools
import MacroTools: @capture

macro splice(iterator, body)
  @assert iterator.head == :call
  @assert iterator.args[1] == :in
  Expr(:..., :(($(esc(body)) for $(esc(iterator.args[2])) in $(esc(iterator.args[3])))))
end

struct MatchFailure
    value
end

"""
Statically get the fieldcount of a type. Useful to avoid runtime calls to
fieldcount.
"""
@generated function evaluated_fieldcount(t::Type{T}) where T
  fieldcount(T)
end

"""
Statically get the fieldnames of a type. Useful to avoid runtime calls to
fieldnames (which includes many allocations).
"""
@generated function evaluated_fieldnames(t::Type{T}) where T
  fieldnames(T)
end

function handle_destruct_fields(value::Symbol, pattern, subpatterns, len, get::Symbol, bound::Set{Symbol}, asserts::Vector{Expr}; allow_splat=true)
    # NOTE we assume `len` is cheap
    fields = []
    seen_splat = false
    for (i,subpattern) in enumerate(subpatterns)
        if (subpattern isa Expr) && (subpattern.head == :(...))
            @assert allow_splat && !seen_splat "Too many ... in pattern $pattern"
            @assert length(subpattern.args) == 1
            seen_splat = true
            push!(fields, (:($i:($len-$(length(subpatterns)-i))), subpattern.args[1]))
        elseif seen_splat
            push!(fields, (:($len-$(length(subpatterns)-i)), subpattern))
        elseif (subpattern isa Expr) && (subpattern.head == :kw)
            T_sym = Meta.quot(subpattern.args[1])
            push!(fields, (:($T_sym), subpattern.args[2]))
        else
            push!(fields, (i, subpattern))
        end
    end
    Expr(:&&,
        if seen_splat
            :($len >= $(length(subpatterns)-1))
        else
            :($len == $(length(subpatterns)))
        end,
        @splice (i, (field, subpattern)) in enumerate(fields) quote
            $(Symbol("$(value)_$i")) = $get($value, $field)
            $(handle_destruct(Symbol("$(value)_$i"), subpattern, bound, asserts))
        end)
end

function handle_destruct(value::Symbol, pattern, bound::Set{Symbol}, asserts::Vector{Expr})
    if pattern == :(_)
        # wildcard
        true
    elseif !(pattern isa Expr || pattern isa Symbol) ||
           pattern == :nothing ||
           @capture(pattern, _quote_macrocall) ||
           @capture(pattern, Symbol(_))
        # constant
        # TODO do we have to be careful about QuoteNode etc?
        quote
            $value == $pattern
        end
    elseif @capture(pattern, subpattern_Symbol)
        # variable
        # if the pattern doesn't match, we don't want to set the variable
        # so for now just set a temp variable
        our_sym = Symbol("variable_$pattern")
        if pattern in bound
            # already bound, check that this value matches
            quote
                $our_sym == $value
            end
        else
            # bind
            push!(bound, pattern)
            quote
                $our_sym = $value;
                true
            end
        end
    elseif @capture(pattern, subpattern1_ || subpattern2_) || (@capture(pattern, f_(subpattern1_, subpattern2_)) && f == :|)
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
    elseif @capture(pattern, subpattern1_ && subpattern2_) || (@capture(pattern, f_(subpattern1_, subpattern2_)) && f == :&)
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
            $(handle_destruct(value, subpattern, bound, asserts)) &&
            let $(bound...)
                # bind variables locally so they can be used in the guard
                $(@splice variable in bound quote
                    $(esc(variable)) = $(Symbol("variable_$variable"))
                end)
                $(esc(guard))
            end
        end
    elseif @capture(pattern, T_(subpatterns__))
        if string(T) == "=>"
            # Syntactic sugar for head => tail
            T = :Cons
        end
        @assert occursin(r"^[A-Z]", string(T)) "Pattern $pattern looks like a struct pattern but $T is probably not a struct type."
        len = length(subpatterns)
        # show([pat.head for pat in subpatterns if pat isa Expr])
        named_fields = [pat.args[1] for pat in subpatterns if (pat isa Expr) && pat.head == :(kw)]
        @assert length(named_fields)==length(unique(named_fields)) "Pattern $pattern has duplicate named arguments: $(named_fields)"
        nNamed = length(named_fields)
        @assert nNamed == 0 || len == nNamed "Pattern $pattern mixes named and positional arguments"
        # struct
        if nNamed == 0
            push!(asserts, quote
                if evaluated_fieldcount($(esc(T))) != $(esc(len))
                    error("Pattern field count is $($(esc(len))) expected $(evaluated_fieldcount($(esc(T))))")
                end
            end)
        else
            # Uses keyword arguments
            struct_name = gensym("$(T)_match")
            type_name = String(T)
            assertcond = true
            for field in named_fields
                local tmp
                tmp = quote $(Meta.quot(field)) in $struct_name end
                assertcond = assertcond ? tmp : Expr(:&&, [tmp assertcond])
            end
            push!(asserts, quote
                if !(let
                        $struct_name = evaluated_fieldnames($(esc(T)))
                        $assertcond
                    end)
                    error("Pattern contains named argument not in the type")
                end
            end)
        end
        quote
            # I would prefer typeof($value) == $(esc(T)) but this doesn't convey type information in Julia 0.6
            $value isa $(esc(T)) &&
            $(handle_destruct_fields(value, pattern, subpatterns, length(subpatterns), :getfield, bound, asserts; allow_splat=false))
        end
    elseif @capture(pattern, (subpatterns__,))
        # tuple
        quote
            ($value isa Tuple) &&
            $(handle_destruct_fields(value, pattern, subpatterns, :(length($value)), :getindex, bound, asserts; allow_splat=true))
        end
    elseif @capture(pattern, [subpatterns__])
        # array
        quote
            ($value isa AbstractArray) &&
            $(handle_destruct_fields(value, pattern, subpatterns, :(length($value)), :getindex, bound, asserts; allow_splat=true))
        end
    elseif @capture(pattern, subpattern_::T_)
        # typeassert
        quote
            ($value isa $(esc(T))) &&
            $(handle_destruct(value, subpattern, bound, asserts))
        end
    else
        error("Unrecognized pattern syntax: $pattern")
    end
end

function handle_match_eq(expr)
    if @capture(expr, pattern_ = value_)
        asserts = Expr[]
        bound = Set{Symbol}()
        body = handle_destruct(:value, pattern, bound, asserts)
        quote
            $(asserts...)
            value = $(esc(value))
            done = false
            $body || throw(MatchFailure(value))
            $(@splice variable in bound quote
                $(esc(variable)) = $(Symbol("variable_$variable"))
            end)
            value
        end
    else
        error("Unrecognized match syntax: $expr")
    end
end

function handle_match_case(value, case, tail, asserts, matchcontinue::Bool)
    if @capture(case, pattern_ => result_)
        bound = Set{Symbol}()
        body = handle_destruct(:value, pattern, bound, asserts)
        if matchcontinue
            quote
                if (!done) && $body
                    try
                        res = let $(bound...)
                            # export bindings
                            $(@splice variable in bound quote
                              $(esc(variable)) = $(Symbol("variable_$variable"))
                              end)
                            $(esc(result))
                        end
                        done = true
                    catch
                        done = false
                    end
                end
                $tail
            end
        else
            quote
                if (!done) && $body
                    res = let $(bound...)
                        # export bindings
                        $(@splice variable in bound quote
                          $(esc(variable)) = $(Symbol("variable_$variable"))
                          end)
                        $(esc(result))
                    end
                    done = true
                end
                $tail
            end
        end
    else
        error("Unrecognized case syntax: $case")
    end
end

function handle_match_cases(value, match ; mathcontinue::Bool = false)
    # assert(mathcontinue)
    tail = nothing
    if @capture(match, begin cases__ end)
        asserts = Expr[]
        for case in reverse(cases)
            tail = handle_match_case(:value, case, tail, asserts, mathcontinue)
        end
        quote
            $(asserts...)
            local value = $(esc(value))
            local done::Bool = false
            local res
            $tail
            if !done
                throw(MatchFailure(value))
            end
            res
        end
    else
        error("Unrecognized match syntax: $value $match")
    end
end

"""
    @match pattern = value

If `value` matches `pattern`, bind variables and return `value`. Otherwise, throw `MatchFailure`.
"""
macro match(expr)
    handle_match_eq(expr)
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
    handle_match_cases(value, cases ; mathcontinue = true)
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
    handle_match_cases(value, cases ; mathcontinue = false)
end

"""
Patterns:

  * `_` matches anything
  * `foo` matches anything, binds value to `foo`
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
