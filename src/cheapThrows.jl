#=
Backtrace-free throws for MetaModelica's control-flow failures.

A `throw` records a backtrace of the whole stack, which is most of what a failure
costs where failures steer the search: fail(), a @match without a matching case,
@matchcontinue moving on to its next case. Inside a catch block the runtime can
throw without recording one: `rethrow(e)` (jl_rethrow_other) puts `e` in place of
the exception being handled and unwinds with that exception's backtrace.

`with_cheap_throws(f)` opens one such catch block around `f` and marks the task
as in a scope. Within it `mm_throw` rethrows over the handled exception when that
is a control-flow value (the scope's marker, a MetaModelica or ImmutableList
failure), and throws as usual otherwise: a real error being handled keeps its
place, so its catch block's `rethrow()` still rethrows it. Outside a scope
`mm_throw` is a plain `throw`, also inside a catch block handling a failure; a
new task is outside (its task-local storage and exception stack start empty).

The price, inside a scope:
- a failure carries the backtrace of the exception it replaced, not its own;
- in a catch block handling a failure, a failure thrown and caught there takes
  the handled one's place, so a later `rethrow()` (or a `finally`'s) propagates
  the later failure. Both are control-flow failures; nothing in OM.jl tells
  them apart.
`CHEAP_THROWS[] = false`, or METAMODELICA_CHEAP_THROWS=false in the environment
at load, throws with full backtraces again, for debugging.
=#

const CHEAP_THROWS = Ref(true)

"""The exception a `with_cheap_throws` scope handles while its body runs; not an error."""
struct CheapThrowScope <: Exception end
const CHEAP_THROW_SCOPE = CheapThrowScope()
Base.showerror(io::IO, ::CheapThrowScope) = print(io, "MetaModelica.with_cheap_throws scope (not an error)")

const _SCOPE_KEY = :MetaModelicaCheapThrows

@inline _inScope() = get(task_local_storage(), _SCOPE_KEY, false)::Bool

#= The exception on top of the current task's exception stack (nothing outside a catch block). =#
@inline _handledException() = ccall(:jl_current_exception, Any, (Any,), current_task())

@inline _isControlFlow(@nospecialize(e)) =
  e isa CheapThrowScope || e isa MetaModelicaException || e isa ImmutableListException

"""
    mm_throw(e)

Throw `e`; without recording a backtrace inside a `with_cheap_throws` scope, when the
exception being handled there is a control-flow value.
"""
@noinline function mm_throw(@nospecialize(e))
  CHEAP_THROWS[] && _inScope() && _isControlFlow(_handledException()) && rethrow(e)
  throw(e)
end

"""
    with_cheap_throws(f)

Call `f()` in a scope where `mm_throw` (and so `fail()` and the match macros' failures)
throws without recording a backtrace. A nested scope is the outer one. Opening a scope
costs one ordinary throw (~0.1 ms on macOS): open it around a large computation, not
per small task.
"""
function with_cheap_throws(f)
  (!CHEAP_THROWS[] || _inScope()) && return f()
  return task_local_storage(_SCOPE_KEY, true) do
    try
      throw(CHEAP_THROW_SCOPE)
    catch
      return f()
    end
  end
end

"""
    @cheap_throws expr

`with_cheap_throws(() -> expr)`.
"""
macro cheap_throws(expr)
  return :(with_cheap_throws(() -> $(esc(expr))))
end
