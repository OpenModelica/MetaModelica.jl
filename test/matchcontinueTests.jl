module MatchContinueTests

using MetaModelica
using Test

@test 2 == @matchcontinue Cons(1, nil) begin
  # MM: case x::_ then fail()
  x <| _ => throw(MatchFailure("Some custom failure here", 0))
  # MM: case (x as 1)::_ then 2*x
  (x && 1) <| _ => 2 * x
  _ => 3
end

#= Try nested matchcontinue =#
@test 1 == @matchcontinue 2 begin
  2 => @match 3 begin
    3 => @match 3 begin
      2 => 1
    end
  end
  _ => 1
end

#= Test support for all wildcard matching =#
@testset "Wildcard test" begin
  begin
    struct foo end
    struct bar end
    a = bar()
    #=Empty fields. Wildcard match=#
    @test 2 == @match a begin
      foo(__) => 1
      bar(__) => 2
    end
  end

  #= Test the new all wild syntax. Needed since I cannot figure out how to get that info from Susan =#
  let
    struct foo1
      a::Any
    end

    struct bar2
      a::Any
      b::Any
    end

    struct baz3
      a::Any
      b::Any
      c::Any
    end

    a = baz3(1, 2, 3)
    @test 4 == begin
      @match a begin
        bar2(__) => 2
        foo1(a=1) => 3
        foo1(__) => 3
        _ => 4
      end
    end

    a = foo1(8)
    @test 1 == @match a begin
      bar2(__) => 2
      foo1(a=7) => 3
      bar2(__) => 5
      bar2(a=1, b=2) => 6
      foo1(__) => 1
    end
  end

  @test begin
    function testSideEffects(a)
      local someVariableWeWantToMutate1 = false
      local someVariableWeWantToMutate2 = false
      begin
        @match a begin
          1 => begin
            someVariableWeWantToMutate1 = true
            someVariableWeWantToMutate2 = true
            ()
          end
        end
        someVariableWeWantToMutate1 && someVariableWeWantToMutate2
      end
    end
    testSideEffects(1)
  end
end

@testset "Matching on member variables" begin
  struct FOO
    a::Any
  end
  foo = FOO(1)
  @test 1 == @match (@match foo.a = 1) begin
    1 => true
    _ => false
  end
end


end #= End module =#

module MMDebugUser
  using MetaModelica
  using MetaModelica.MM_Debug: @matchcontinue
  function pick(x::Int)::Int
    @matchcontinue x begin
      1 => fail()
      1 => 10
      _ => 20
    end
  end
  function nothingMatches(x::Int)::Int
    @matchcontinue x begin
      1 => fail()
    end
  end
end

@testset "MM_Debug.@matchcontinue logs swallowed exceptions" begin
  MetaModelica.MM_Debug.clear!()
  @test MMDebugUser.pick(1) == 10
  @test MMDebugUser.pick(2) == 20
  @test length(MetaModelica.MM_Debug.LOG) == 1
  @test MetaModelica.MM_Debug.LOG[1].case_num == 1
  @test_throws MatchFailure MMDebugUser.nothingMatches(1)
  @test MetaModelica.MM_Debug.LOG[end].case_num == 0
  @test occursin("ALL CASES FAILED", MetaModelica.MM_Debug.LOG[end].source)
  #= summarize() counts per exception type, print_log() lists the last entries. =#
  local report = mktemp() do path, io
    redirect_stdout(io) do
      MetaModelica.MM_Debug.summarize()
      MetaModelica.MM_Debug.print_log(last_n = 1)
    end
    flush(io)
    read(path, String)
  end
  #= pick(1) swallowed one failure, nothingMatches(1) one failure and the final MatchFailure. =#
  @test occursin("3 swallowed exceptions", report)
  @test occursin(r"MetaModelicaGeneralException +2", report) && occursin(r"MatchFailure +1", report)
  @test occursin("[case 0]", report) && !occursin("[case 1]", report)
  MetaModelica.MM_Debug.clear!()
  @test isempty(MetaModelica.MM_Debug.LOG)
  local empty = mktemp() do path, io
    redirect_stdout(MetaModelica.MM_Debug.summarize, io)
    flush(io)
    read(path, String)
  end
  @test occursin("Log is empty.", empty)
end
