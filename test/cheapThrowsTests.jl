#= Backtrace-free control-flow throws (src/cheapThrows.jl). =#
using MetaModelica
using Test

@noinline _ctDepth(n) = n == 0 ? MetaModelica.fail() : _ctDepth(n - 1)
#= Whether a caught failure's backtrace holds the frames that threw it. =#
_ctOwnBacktrace() = try
  _ctDepth(3)
catch
  any(f -> f.func === :_ctDepth, stacktrace(catch_backtrace()))
end
_ctMatch(x) = @match x begin
  1 => :one
end
_ctContinue(x) = @matchcontinue x begin
  _ => MetaModelica.fail()
  _ => :second
end

@test_throws MetaModelica.MetaModelicaGeneralException MetaModelica.fail()
#= Outside a scope: a plain throw, with its own backtrace. =#
@test _ctOwnBacktrace()
#= In a scope failures are caught as before, without a backtrace of their own. =#
@test with_cheap_throws() do
  count(1:100) do _
    try
      _ctDepth(50)
      false
    catch e
      e isa MetaModelica.MetaModelicaGeneralException
    end
  end
end == 100
@test !with_cheap_throws(_ctOwnBacktrace)
#= Switched off: their own backtrace again. =#
MetaModelica.CHEAP_THROWS[] = false
try
  @test with_cheap_throws(_ctOwnBacktrace)
finally
  MetaModelica.CHEAP_THROWS[] = true
end
#= A real error being handled keeps its place: rethrow() in its catch block rethrows it,
   also after a failure was thrown and caught there. =#
@test_throws KeyError with_cheap_throws() do
  try
    Dict{Int, Int}()[1]
  catch
    try
      MetaModelica.fail()
    catch
    end
    rethrow()
  end
end
#= finally blocks run and the failure propagates out of the scope. =#
ran = Ref(false)
@test_throws MetaModelica.MetaModelicaGeneralException with_cheap_throws() do
  try
    MetaModelica.fail()
  finally
    ran[] = true
  end
end
@test ran[]
#= The match macros: MatchFailure without a matching case; @matchcontinue moves on. =#
@test_throws MatchFailure with_cheap_throws(() -> _ctMatch(2))
@test with_cheap_throws(() -> _ctContinue(1)) === :second
@test @cheap_throws(_ctContinue(1)) === :second
#= Outside a scope, also in a catch block handling a failure: a plain throw with its own backtrace. =#
@test try
  MetaModelica.fail()
catch
  _ctOwnBacktrace()
end
#= Tasks started in a scope are outside it. =#
@test with_cheap_throws(() -> fetch(Threads.@spawn _ctOwnBacktrace()))
#= In a scope, a failure thrown and caught in a catch block handling another failure takes its
   place: rethrow() there propagates the later failure (documented in cheapThrows.jl). =#
@test with_cheap_throws() do
  try
    try
      MetaModelica.fail("A")
    catch
      try
        MetaModelica.fail("B")
      catch
      end
      rethrow()
    end
  catch e
    e.msg
  end
end == "B"
#= Nested scopes reuse the outer one; the value passes through. =#
@test with_cheap_throws(() -> with_cheap_throws(() -> 42)) == 42
