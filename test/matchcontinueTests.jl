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
end
