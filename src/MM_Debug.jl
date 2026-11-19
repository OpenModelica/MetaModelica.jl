"""
    MM_Debug

`@matchcontinue` that logs every exception a case swallows. The same macro name as `MetaModelica.@matchcontinue`,
built by the same code (`handle_match_cases` with a `swallowHook`), so a debug run swaps one import:

    using MetaModelica.MM_Debug: @matchcontinue

An explicit import wins over the implicit `using MetaModelica`. Remove the line to return to the plain macro.
The log is `MM_Debug.LOG`; `clear!()` before a run, `summarize()` or `print_log()` after.
"""
module MM_Debug

#=
The expansion of the match macros names MetaModelicaException, ImmutableListException and
MatchFailure unqualified. Unqualified names resolve in the module of the macro, so they are
imported here.
=#
import ..MetaModelicaException, ..ImmutableListException, ..MatchFailure
import ..handle_match_cases, ..replaceLineNum, ..MATCHCONTINUE_FILE

export @matchcontinue
export LOG, clear!, summarize, print_log

const LogEntry = NamedTuple{(:case_num, :exception_type, :message, :source), Tuple{Int, String, String, String}}

"""
Swallowed exceptions. Fields: `case_num` (1-based; 0 when all cases failed), `exception_type`, `message`, `source`.
"""
const LOG = LogEntry[]

"""Entries kept in `LOG`; later ones are dropped (batch runs)."""
const MAX_LOG = Ref{Int}(5000)

"""Empty `LOG`."""
function clear!()::Nothing
  empty!(LOG)
  return nothing
end

"""Print the number of swallowed exceptions per exception type."""
function summarize()::Nothing
  if isempty(LOG)
    println("Log is empty.")
    return nothing
  end
  local groups = Dict{String, Int}()
  for entry in LOG
    groups[entry.exception_type] = get(groups, entry.exception_type, 0) + 1
  end
  println("MM_Debug log: ", length(LOG), " swallowed exceptions")
  for (etype, count) in sort(collect(groups), by = x -> -x[2])
    println("  ", rpad(etype, 50), " ", count)
  end
  return nothing
end

"""Print the last `last_n` entries of `LOG`."""
function print_log(; last_n::Int = 20)::Nothing
  local entries = length(LOG) > last_n ? LOG[(end - last_n + 1):end] : LOG
  for e in entries
    println("  [case ", e.case_num, "] ", e.exception_type, ": ", first(e.message, 120))
    isempty(e.source) || println("    at ", e.source)
  end
  return nothing
end

"""
The hook of the `@matchcontinue` expansion: record one swallowed exception.
"""
function log_swallowed(case_num::Int, e, source::String)::Nothing
  length(LOG) >= MAX_LOG[] && return nothing
  local msg::String = try
    first(sprint(showerror, e), 200)
  catch
    string(e)
  end
  push!(LOG, (case_num = case_num, exception_type = string(typeof(e)), message = msg, source = source))
  return nothing
end

"""
    @matchcontinue value begin
        pattern1 => result1
        pattern2 => result2
        ...
    end

`MetaModelica.@matchcontinue` plus a log entry in `LOG` for every swallowed exception.
"""
macro matchcontinue(value, cases)
  res = handle_match_cases(value, cases; matchcontinue=true, calling_module=__module__, source=__source__, swallowHook=log_swallowed)
  replaceLineNum(res, MATCHCONTINUE_FILE, __source__)
  res
end

end #= MM_Debug =#
