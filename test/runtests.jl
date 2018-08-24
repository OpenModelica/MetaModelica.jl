module TestMetaModelica

using MetaModelica
using Test

@testset "MetaModelica" begin

@testset "@match" begin

@test 1 == @match Cons(1,nil()) begin
  # case x::_ then x
  Cons(head=x) => x
  # else 2
  _ => 2
end

@test_throws MatchFailure 1 == @match Cons(1,nil()) begin
  # case 2::_ then x // unbound variable error
  Cons(head=2) => x
end

@test @match Cons(1,nil()) begin
  # case _::{} then true, using the Nil type
  Cons(tail=Nil) => true
end

@test @match Cons(1,nil()) begin
  # case _::{} then true, using the Nil value
  Cons(tail=Nil()) => true
end

@test 3 == @match 1 => 2 => nil() begin
  # case x::y::{} then x+y
  (x => y => Nil()) => x+y
end

end

@testset "@matchcontinue" begin

@test 2 == @matchcontinue Cons(1,nil()) begin
  # case x::_ then fail()
  Cons(head=x) => throw(MatchFailure)
  # case (x as 1)::_ then 2*x
  Cons(x && 1,_) => 2*x
  _ => 3
end

end

end

end
