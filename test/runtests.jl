module TestMetaModelica

using MetaModelica
using Test

@testset "MetaModelica" begin

@testset "@match" begin
  include("./matchTests.jl")
  @testset "@matchcontinue" begin
    include("./matchcontinueTests.jl")
  end
end

@testset "list" begin
  include("./listTests.jl")
end

@testset "metaModelicatypes" begin
    include("./metaModelicaTypeTest.jl")
end
  
@testset "Uniontype" begin
  include("./uniontypeTests.jl")
end #=End of uniontype =#    

@testset "Function extension test" begin
  include("./functionExtensionTest.jl")
end #= Function extension test =#

@testset "Runtime tests" begin
  include("./runtimeTest.jl")
end

@testset "Cross module match" begin
  include("crossModuleMatchTest.jl")
end

@testset "Should fail tests" begin
  include("shouldFailTests.jl")
end
  
end #= End MetaModelica testset =#

end #= End of TestMetaModelica =#
