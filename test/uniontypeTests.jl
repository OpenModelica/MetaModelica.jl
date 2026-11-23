module UniontypeTests

using MetaModelica
using Test

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

someIMG = IMG(1, 2)

@test someIMG.r == 1

@test someIMG.i == 2

function realOrIMG(a::number)
  @match a begin
    IMG(x, y) => (x, y)
    REAL(x) => x
  end
end

@test realOrIMG(REAL(1)) == 1

@test realOrIMG(IMG(1, 2)) == (1, 2)

#Check that uniontypes work with match..
@Uniontype uK begin
  @Record SCOTLAND begin
  end
  @Record WALES begin
  end
  @Record ENGLAND begin
  end
  @Record NorthIreland begin
  end
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

#= The short @Record form keeps every field; a record may have none. =#
@Uniontype ShortForm begin
  @Record SHORT_ONE a::Int
  @Record SHORT_TWO a::Int b::String
  @Record SHORT_NONE
end

@testset "Short @Record form" begin
  @test fieldnames(SHORT_TWO) == (:a, :b)
  @test SHORT_TWO(1, "x").b == "x"
  @test fieldnames(SHORT_ONE) == (:a,)
  @test fieldnames(SHORT_NONE) == ()
  @test SHORT_NONE() isa ShortForm
end

end
