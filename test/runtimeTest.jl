#= Various tests for the MetaModelica runtime =#
module RuntimeTests

using MetaModelica
using Test
#= Creates arr = {3, 3, 3} =#

@testset "Testing Array creation" begin
  global arr = arrayCreate(3, 3)
  for i in arr
    @test i == 3
  end
  @test arrayEmpty(arr) == false
  @test arrayLength(arr) == 3
  @test arrayGet(arr, 3) == 3
end

@testset "Common conversions betwen MetaArrays and Lists" begin
  local arr = [1,2,3]
  local lst = arrayList(arr)
  @test listHead(lst) == 1
  @test listEmpty(lst) == false
  @test listMember(4, lst) == false
  @test listMember(3, lst) == true
  @test listHead(list(1,2,3)) == 1
  lst2::List{Int64} = list(1,2,3)
  lst2 = listReverse(lst2)
  @test listHead(lst2) == 3
  @test list(2, 3) == listRest(list(1, 2, 3))
  lstA = list(1,2,3)
  lstB = list(1,2,3)
  lstC = listAppend(lstA, lstB)
  @test listLength(lstC) == 6
  lstD = listReverse(lstC)
  @test listHead(lstD) == 3
  @test listMember(6, lstD) == false
  @test listMember(3, lstD) == true
  @test listGet(lstD, 1) == 3
  @test listGet(lstD, 3) == 1
  @test listGet(lstD, 6) == 1
  #=Try to convert a list to an array=#
  arr = listArray(lstD)
  @test length(arr) == 6
end

@Uniontype Complex begin
  @Record COMPLEX begin
    r::ModelicaReal
    i::ModelicaReal
  end
end

@testset "Complex structure test" begin
  @testset "Testing list of complex types" begin
    local lst::List{Complex} = list(COMPLEX(0,0), COMPLEX(0,0), COMPLEX(0,0))
    @test length(lst) == 3
    @test listHead(lst) == COMPLEX(0, 0)
    @test listLength(listReverse(lst)) == 3
    local lst2::List{Complex} = COMPLEX(0,0) => lst
    @test length(lst2) == 4
    local lst3::List{Complex} = listAppend(lst, lst2)
    @test length(lst3) == 7
  end
  @testset "Testing arrays of complex types" begin
    #=Array of Complex elements to a List of Complex elements=#
    local A::Array{Complex} = arrayCreate(5, COMPLEX(0, 0))
    @test length(A) == 5
    local L::List{Complex} = arrayList(A)
    @test length(L) == 5
  end
end

@testset "Testing array copy" begin
  arr2 = arrayCopy(arr)
  @test arrayLength(arr2) == 3
end

@testset "Testing tick()" begin
  #= Testing tick =#
  @test tick() == 1
  @test tick() == 2
  @test tick() == 3
end


end
