#= Tuple, array, type-assertion and or-patterns of @match, and @unsafematch. =#
module PatternTests

using MetaModelica
using Test

struct P
  a::Any
  b::Any
end

@testset "Tuple and array patterns" begin
  @test (@match (1, 2, 3) begin
    (a, b...) => b
    _ => ()
  end) == (2, 3)
  @test (@match [1, 2, 3] begin
    [a, b...] => b
    _ => Int[]
  end) == [2, 3]
  @test (@match [1, 2, 3] begin
    [a..., c] => c
    _ => 0
  end) == 3
  @test (@match [1] begin
    [a, b] => 2
    [a] => 1
  end) == 1
  @test (@match (1, "a") begin
    (x::Int, y::String) => x
    _ => 0
  end) == 1
  @test (@match 1 begin
    x::String => 0
    x::Int => 1
  end) == 1
end

@testset "Or-patterns" begin
  local f = x -> @match x begin
    1 || 2 => "small"
    _ => "other"
  end
  @test f(1) == "small" && f(2) == "small" && f(3) == "other"
  #= A variable bound in both branches is bound after the match. =#
  local g = x -> @match x begin
    P(a, 1) || P(1, a) => a
    _ => 0
  end
  @test g(P(5, 1)) == 5 && g(P(1, 7)) == 7 && g(P(2, 2)) == 0
end

@testset "@unsafematch" begin
  @test (@unsafematch 3 begin
    1 => 10
    x => x + 1
  end) == 4
  #= No case matches: the value itself. =#
  @test (@unsafematch 3 begin
    1 => 10
  end) == 3
  @unsafematch P(a, b) = P(1, 2)
  @test a == 1 && b == 2
end

end #= PatternTests =#
