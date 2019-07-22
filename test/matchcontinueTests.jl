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
struct foo
  a
end

struct bar
  a
  b
end

struct baz
  a
  b
  c
end

#= Test the new all wild syntax. Needed since I cannot figure out how to get that info from Susan =#
a = baz(1, 2, 3)

@test 4 == begin
  @match a begin
    bar(__) => 2
    foo(a=1) => 3
    foo(__) => 3
    _ => 4
  end
end

a = foo(8)
@test 1 == @match a begin
  bar(__) => 2
  foo(a=7) => 3
  bar(__) => 5
  bar(a = 1, b = 2) => 6
  foo(__) => 1
end

end
