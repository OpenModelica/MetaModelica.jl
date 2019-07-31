module MatchTests

using MetaModelica
using Test

@test 1 == @match Cons(1,nil()) begin
  # case x::_ then x
  Cons(head=x) => x
  # else 2
  _ => 2
end

@test_throws MatchFailure 1 == @match 1 <| nil() begin
  # case 2::_ then x // unbound variable error
  Cons(head=2) => x
end

@test @match Cons(1,nil()) begin
  # case _::{} then true, using the Nil type
  Cons(tail=nothing) => true
end

@test @match Cons(1,nil()) begin
  # case _::{} then true, using the Nil value
  Cons(tail=nothing) => true
end

@test 3 == @match 1 => 2 => nil() begin
  # case x::y::{} then x+y
  (x => y => nil()) => x+y
end

@test 1 == @match 1 <| nil() begin
  # case x::y::{} then x+y
  x <| nil() => x
end

@test 3 == @match 1 <| 2 <| nil() begin
  # case x::y::{} then x+y
  x <| y <| nil() => x+y
end

@test 1 == @match list(1,2) begin
  # case x::2::{} then x
  Cons(head=x, tail=Cons(head=2, tail=nothing)) => x
end

#= More advanced matching =#
let
  H,T = @match list(1,2,3) begin
    H <| T => let
      H, T
    end
  end
  @test H == 1
  @test T == list(2,3)
end

let
  T = list(1,2,3)
  H,T = @match T begin    
    H <| T => let
      H, T
    end
  end
  @test H == 1
  @test T == list(2,3)
end

#= Wildcard with structs =#
struct foo end
struct bar end
struct barBar end
a = barBar()
@test 1 == @match a begin
  foo() => 2
  bar() => 3
  _    => 1 
end

end
