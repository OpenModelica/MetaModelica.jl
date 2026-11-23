using MetaModelica
using Test

@testset "MetaModelica" begin

  @testset "@match" begin
    include("./matchTests.jl")
    @testset "Tuple, array and or-patterns, @unsafematch" begin
      include("./patternTests.jl")
    end
    @testset "@matchcontinue" begin
      include("./matchcontinueTests.jl")
    end
    @testset "@fastmatch" begin
      include("./fastmatchTests.jl")
    end
    @testset "compacted uniontype tag dispatch" begin
      include("./compactedUniontypeTests.jl")
    end
    @testset "@T_Uniontype, isvariant, variantof" begin
      include("./taggedUniontypeTests.jl")
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

  @testset "Runtime builtins" begin
    include("./runtimeBuiltinsTests.jl")
  end

  @testset "Cross module match" begin
    include("crossModuleMatchTest.jl")
  end

  @testset "Should fail tests" begin
    include("shouldFailTests.jl")
  end

  @testset "Cheap throws" begin
    include("cheapThrowsTests.jl")
  end

  @testset "Exported names" begin
    include("exportTests.jl")
  end

end #= End MetaModelica testset =#
