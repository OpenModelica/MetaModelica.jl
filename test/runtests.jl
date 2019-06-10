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

@test 1 == @match list(1,2) begin
  # case x::2::{} then x
  Cons(head=x, tail=Cons(head=2, tail=Nil())) => x
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

@testset "list" begin

@test 0 == begin
  Ints = MetaModelica.List{Int}
  a::Ints = nil()
  length(a)
end

end

@testset "metaModelicatypes" begin
    
function f(a::ModelicaReal, b::ModelicaReal)::AbstractFloat
    return a + b
end

function f2(a::ModelicaInteger)::ModelicaInteger
    return a
end        
    
@test_throws MethodError f(true, true)

@test_throws MethodError f(true, 1)
    
@test_throws MethodError f(f2(1), f2(1))

@test typeof(2.0) == typeof(f(1,1))

@test typeof(2) != typeof(f(1,1))

end

end #= End MetaModelica testset =#

end #= End of TestMetaModelica =#
