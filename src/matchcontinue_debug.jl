#=
  @matchcontinue_debug - Diagnostic variant of @matchcontinue

  Same semantics as @matchcontinue but logs every swallowed exception.
  Helps identify translator-level errors hidden inside matchcontinue chains.

  Usage: Replace @matchcontinue with @matchcontinue_debug in specific functions
  to see which cases are tried and why they fail.

  The log is stored in MATCHCONTINUE_DEBUG_LOG (a global vector).
  Call clear_matchcontinue_log!() before a test run, then inspect the log after.
=#

"""
Global log buffer for @matchcontinue_debug.
Each entry is a NamedTuple with fields:
  - case_num::Int - which case failed (1-based)
  - exception_type::String - typeof(e)
  - message::String - short error description
  - source::String - source location if available
"""
const MATCHCONTINUE_DEBUG_LOG = Vector{NamedTuple{(:case_num, :exception_type, :message, :source), Tuple{Int, String, String, String}}}()

"""Maximum entries to keep (prevents memory blow-up in batch runs)."""
const MATCHCONTINUE_DEBUG_MAX_LOG = Ref(5000)

"""Clear the debug log."""
function clear_matchcontinue_log!()
    empty!(MATCHCONTINUE_DEBUG_LOG)
end

"""Print a summary of the debug log grouped by exception type."""
function summarize_matchcontinue_log()
    isempty(MATCHCONTINUE_DEBUG_LOG) && (println("Log is empty."); return)

    groups = Dict{String, Int}()
    for entry in MATCHCONTINUE_DEBUG_LOG
        key = entry.exception_type
        groups[key] = get(groups, key, 0) + 1
    end

    println("matchcontinue_debug log: $(length(MATCHCONTINUE_DEBUG_LOG)) swallowed exceptions")
    for (etype, count) in sort(collect(groups), by=x->-x[2])
        println("  $(rpad(etype, 50)) $count")
    end
end

"""Print the last N entries of the debug log."""
function print_matchcontinue_log(; last_n::Int=20)
    entries = if length(MATCHCONTINUE_DEBUG_LOG) > last_n
        MATCHCONTINUE_DEBUG_LOG[end-last_n+1:end]
    else
        MATCHCONTINUE_DEBUG_LOG
    end
    for (i, e) in enumerate(entries)
        println("  [case $(e.case_num)] $(e.exception_type): $(first(e.message, 120))")
        if !isempty(e.source)
            println("    at $(e.source)")
        end
    end
end

"""
Internal: log a swallowed exception from @matchcontinue_debug.
Called from the generated catch block.
"""
function _mc_debug_log(case_num::Int, e, source::String)
    length(MATCHCONTINUE_DEBUG_LOG) >= MATCHCONTINUE_DEBUG_MAX_LOG[] && return
    msg = try
        first(sprint(showerror, e), 200)
    catch
        string(e)
    end
    push!(MATCHCONTINUE_DEBUG_LOG, (
        case_num = case_num,
        exception_type = string(typeof(e)),
        message = msg,
        source = source,
    ))
    return
end


"""
Debug variant of handle_match_case. Identical to the original except:
- Adds a case_num counter
- Logs swallowed exceptions via _mc_debug_log
"""
function handle_match_case_debug(value, case, tail, asserts, case_num::Int, source_hint::String;
                                  calling_module::Union{Module,Nothing}=nothing)
    if @capture(case, pattern_ => result_)
        bound = Set{Symbol}()
        body = handle_destruct(:value, pattern, bound, asserts; calling_module=calling_module)
        # Extract a short pattern hint for the log
        pat_str = string(pattern)
        if length(pat_str) > 60
            pat_str = first(pat_str, 57) * "..."
        end
        quote
            if (!__omc_match_done) && $body
                try
                    res = let $(bound...)
                        $(@splice variable in bound quote
                            $(esc(variable)) = $(Symbol("variable_", variable))
                        end)
                        $(esc(result))
                    end
                    __omc_match_done = true
                catch e
                    if !isa(e, MetaModelicaException) && !isa(e, ImmutableListException)
                        if isa(e, MatchFailure)
                            println("MatchFailure:" + e.msg)
                        else
                            showerror(stderr, e, catch_backtrace())
                        end
                        rethrow(e)
                    end
                    # DEBUG: log the swallowed exception
                    _mc_debug_log($case_num, e, $source_hint * " case " * $pat_str)
                    __omc_match_done = false
                end
            end
            $tail
        end
    else
        error("Unrecognized case syntax: $case")
    end
end

"""
Debug variant of handle_match_cases. Uses handle_match_case_debug instead of
handle_match_case for the matchcontinue path.
"""
function handle_match_cases_debug(value, match::Expr; calling_module::Union{Module,Nothing}=nothing,
                                   source_hint::String="")
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
    # Build the chain in reverse (last case first, becomes innermost)
    for (rev_idx, case) in enumerate(reverse(cases))
        case_num = length(cases) - rev_idx + 1
        tail = handle_match_case_debug(:value, case, tail, asserts, case_num, source_hint;
                                        calling_module=calling_module)
        if line !== nothing
            replaceLineNum(tail, @__FILE__, line)
        end
    end
    # Always include the MatchFailure check (matchcontinue semantics)
    quote
        $(asserts...)
        local value = $(esc(value))
        local __omc_match_done::Bool = false
        local res
        $tail
        if !__omc_match_done
            _mc_debug_log(0, MatchFailure("all cases exhausted", typeof(value)),
                          $source_hint * " ALL CASES FAILED")
            throw(MatchFailure("unfinished match for type", typeof(value)))
        end
        res
    end
end

"""
    @matchcontinue_debug value begin
        pattern1 => result1
        pattern2 => result2
        ...
    end

Diagnostic variant of @matchcontinue. Same semantics, but logs every
swallowed exception to MATCHCONTINUE_DEBUG_LOG.

Use clear_matchcontinue_log!() before a run and summarize_matchcontinue_log() after.
"""
macro matchcontinue_debug(value, cases)
    source_hint = string(__source__.file, ":", __source__.line)
    res = handle_match_cases_debug(value, cases;
                                    calling_module=__module__,
                                    source_hint=source_hint)
    replaceLineNum(res, @__FILE__, __source__)
    res
end

export @matchcontinue_debug
export MATCHCONTINUE_DEBUG_LOG, clear_matchcontinue_log!, summarize_matchcontinue_log, print_matchcontinue_log
