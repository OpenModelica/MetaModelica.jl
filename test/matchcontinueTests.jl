module MatchContinueTests

using MetaModelica
using Test

@test 2 == @matchcontinue Cons(1,nil()) begin
  # case x::_ then fail()
  Cons(head=x) => throw(MatchFailure)
  # case (x as 1)::_ then 2*x
  Cons(x && 1,_) => 2*x
  _ => 3
end

#= Try nested matchcontinue =#
@test 1 == @matchcontinue 2 begin
  2 => @match 3 begin
    3 =>  @match 3 begin
      2 => 1
    end
  end
  _ => 1
end

#= Test support for all wildcard matching =#
@testset "Wildcard test" begin
  begin
    struct foo
    end
    struct bar
    end
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
      a
    end

    struct bar2
      a
      b
    end
    
    struct baz3
      a
      b
      c
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
      bar2(a = 1, b = 2) => 6
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
        println("1:$someVariableWeWantToMutate1 && 2:$someVariableWeWantToMutate2")
        someVariableWeWantToMutate1 && someVariableWeWantToMutate2
      end
    end
    testSideEffects(1)
  end
end
end #= End module =#
