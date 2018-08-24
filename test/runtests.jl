module TestMetaModelica

using MetaModelica
using Test

@testset "MetaModelica" begin

@testset "@match" begin

@test 1 == @match Cons(1,nil()) begin
  Cons(head=x) => x
  _ => 2
end

@test_throws MatchFailure 1 == @match Cons(1,nil()) begin
  Cons(head=2) => x
end

@test @match Cons(1,nil()) begin
  Cons(tail=Nil) => true
end

@test @match Cons(1,nil()) begin
  Cons(tail=Nil()) => true
end

@test 3 == @match 1 => 2 => nil() begin
  (x => y => Nil()) => x+y
end

end

@testset "@matchcontinue" begin

@test 2 == @matchcontinue Cons(1,nil()) begin
  Cons(head=x) => throw(MatchFailure)
  Cons(x && 1,_) => 2*x
  _ => 3
end

end

end

end
