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

@test 3 == begin
  Ints = MetaModelica.List{Int}
  a::Ints = list(1, 2, 3)
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
@testset "Uniontype" begin

@Uniontype number begin
  @Record REAL begin
    r
  end    
  @Record IMG begin
    r
    #We can ofcourse have comments here :D#  
    i
  end
end

someIMG = IMG(1,2)
    
@test someIMG.r == 1

@test someIMG.i == 2

function realOrIMG(a::number)
  @match a begin
    IMG(x,y) => (x,y)
    REAL(x) => x
  end    
end

@test realOrIMG(REAL(1)) == 1

@test realOrIMG(IMG(1,2)) == (1,2)

#Check that uniontypes work with match..

@Uniontype uK begin
  @Record SCOTLAND "Haggis"
  @Record WALES "Cawl"
  @Record ENGLAND "Tea"
end

function forgotWales(x::uK)
  @match x begin
    ENGLAND() => "ok"
    SCOTLAND() => "ok"
  end
end

@test_throws MatchFailure forgotWales(WALES()) 
#= Tests mutally recursive Uniontypes =#
#= N.B: We have to inform Julia through forward declarations as a workaround for now=, see the following issue, as of 2019 Julia does not support this. MM does however: https://github.com/JuliaLang/julia/issues/269#    
=#

@UniontypeDecl NICE_NUMBER
@UniontypeDecl NUMBER
println(@macroexpand @UniontypeDecl NUMBER)
    
@Uniontype NICE_NUMBER begin
    @Record CONCRETE_NICE_NUMBER begin
    r::NUMBER
    end
end
  
@Uniontype NUMBER begin
  @Record REAL1 begin
    r::NICE_NUMBER
  end    
  @Record IMG1 begin
    r::NICE_NUMBER
    i
  end
  @Record BASE begin
    i
  end
end

@test_nowarn REAL1(CONCRETE_NICE_NUMBER(BASE(4)))
    
end #=End of uniontype =#
    
end

end #= End MetaModelica testset =#

end #= End of TestMetaModelica =#
