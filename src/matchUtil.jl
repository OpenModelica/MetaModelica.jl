module MatchUtil

export check_duplicate_case_head!,
       check_return_type_uniformity,
       check_empty_cases,
       check_unreachable_after_wildcard,
       try_resolve_type,
       check_pattern_arity,
       check_pattern_named_fields

#= strictness ∈ (:error, :warn, :silent) =#

_locPrefix(source::Union{LineNumberNode,Nothing}) =
    source === nothing ? "" : "$(source.file):$(source.line): "

#= Returns the resolved value or `nothing` when expansion-time lookup fails =#
#= (forward references, unimported modules, parametric heads, etc.). =#
function try_resolve_type(T, mod::Module)
    try
        return Core.eval(mod, T)
    catch
        return nothing
    end
end

function check_duplicate_case_head!(seen::Vector{Symbol},
                                    type_sym::Symbol;
                                    macro_name::AbstractString,
                                    value,
                                    source::Union{LineNumberNode,Nothing}=nothing,
                                    strictness::Symbol = :error)::Bool
    if type_sym in seen
        local msg = string(_locPrefix(source),
                           "Duplicate case for type $(type_sym). The macro $(macro_name) only allows one case per type")
        if strictness === :error
            error(msg)
        elseif strictness === :warn
            @warn msg
        end
        return false
    end
    push!(seen, type_sym)
    return true
end

#= Skipped silently when inference returns Any (imprecise). =#
function check_return_type_uniformity(funcName::Symbol,
                                      types::Vector{Symbol},
                                      mod::Module;
                                      macro_name::AbstractString,
                                      value,
                                      source::Union{LineNumberNode,Nothing}=nothing,
                                      strictness::Symbol = :warn)::Nothing
    local funcRef
    try
        funcRef = Core.eval(mod, funcName)
    catch
        return nothing
    end
    local rts = Any[]
    for type_sym in types
        local T
        try
            T = Core.eval(mod, type_sym)
        catch
            return nothing
        end
        local rt
        try
            rt = first(Base.return_types(funcRef, Tuple{T}))
        catch
            return nothing
        end
        push!(rts, rt)
    end
    if isempty(rts) || any(==(Any), rts)
        return nothing
    end
    local uniqueRts = unique(rts)
    if length(uniqueRts) > 1
        local pairs = join(("$(t) -> $(r)" for (t, r) in zip(types, rts)), ", ")
        local msg = string(_locPrefix(source),
                           "Non-uniform return types in $(macro_name) $(value). ",
                           "All cases must return the same type. Got: ", pairs)
        if strictness === :error
            error(msg)
        else
            @warn msg
        end
    end
    return nothing
end

function check_empty_cases(cases::Vector{Expr};
                            macro_name::AbstractString,
                            value,
                            source::Union{LineNumberNode,Nothing}=nothing,
                            strictness::Symbol = :error)::Nothing
    if isempty(cases)
        local msg = string(_locPrefix(source),
                           "$(macro_name) $(value): no cases. The match block is empty")
        if strictness === :error
            error(msg)
        elseif strictness === :warn
            @warn msg
        end
    end
    return nothing
end

#= Walks cases in source order; flags any case that follows a `_ => ...` arm. =#
function check_unreachable_after_wildcard(cases::Vector{Expr};
                                          macro_name::AbstractString,
                                          value,
                                          source::Union{LineNumberNode,Nothing}=nothing,
                                          strictness::Symbol = :warn)::Nothing
    local wildcardCase::Union{Nothing,Expr} = nothing
    for c in cases
        if !(isa(c, Expr) && c.head === :call && length(c.args) == 3 && c.args[1] === :(=>))
            continue
        end
        local pat = c.args[2]
        if wildcardCase !== nothing
            local msg = string(_locPrefix(source),
                               "$(macro_name) $(value): unreachable case `$(c)` after wildcard `$(wildcardCase)`")
            if strictness === :error
                error(msg)
            else
                @warn msg
            end
        end
        if pat === :_
            wildcardCase = c
        end
    end
    return nothing
end

#= Returns true if a static fieldcount/fieldnames query is sound for `T`. =#
_isStaticallyKnown(T) = T isa Type && isstructtype(T) && !isabstracttype(T)

function check_pattern_arity(T, len::Integer;
                              macro_name::AbstractString,
                              type_label::AbstractString = string(T),
                              source::Union{LineNumberNode,Nothing}=nothing,
                              strictness::Symbol = :error)::Nothing
    _isStaticallyKnown(T) || return nothing
    local fc = fieldcount(T)
    if fc < len
        local msg = string(_locPrefix(source),
                           "$(macro_name): pattern for $(type_label) has $(len) positional argument(s) but the type has $(fc) field(s)")
        if strictness === :error
            error(msg)
        elseif strictness === :warn
            @warn msg
        end
    end
    return nothing
end

function check_pattern_named_fields(T, fields::Vector{Symbol};
                                     macro_name::AbstractString,
                                     type_label::AbstractString = string(T),
                                     source::Union{LineNumberNode,Nothing}=nothing,
                                     strictness::Symbol = :error)::Nothing
    _isStaticallyKnown(T) || return nothing
    local fns = fieldnames(T)
    for f in fields
        if !(f in fns)
            local msg = string(_locPrefix(source),
                               "$(macro_name): `$(f)` is not a field of $(type_label). Fields: $(fns)")
            if strictness === :error
                error(msg)
            elseif strictness === :warn
                @warn msg
            end
        end
    end
    return nothing
end

end #= module MatchUtil =#
