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
  local arr = [1, 2, 3]
  local lst = arrayList(arr)
  @test listHead(lst) == 1
  @test listEmpty(lst) == false
  @test listMember(4, lst) == false
  @test listMember(3, lst) == true
  @test listHead(list(1, 2, 3)) == 1
  lst2::List{Int64} = list(1, 2, 3)
  lst2 = listReverse(lst2)
  @test listHead(lst2) == 3
  @test list(2, 3) == listRest(list(1, 2, 3))
  lstA = list(1, 2, 3)
  lstB = list(1, 2, 3)
  lstC = listAppend(lstA, lstB)
  @test listLength(lstC) == 6
  @test listAppend(list(1, 2, 3), list(4.0, 5)) == list(1, 2, 3, 4, 5)
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
  @Record COMPLEX_INT begin
    r::ModelicaInteger
    i::ModelicaInteger
  end
end

@Uniontype EvenMoreComplex begin
  @Record EVENMORECOMPLEX begin
    lst::List{Complex}
  end
end

@Uniontype EvenMoreComplexVector begin
  @Record EVENMORECOMPLEXVECTOR begin
    lst::Vector{Complex}
  end
end


@Uniontype InnerLists begin
  @Record INNERLISTS begin
    a::String
    lst0::List{String}
    lst1::List{String}
    lst2::List{String}
  end
end

@Uniontype InnerVectors begin
  @Record INNERVECTORS begin
    a::String
    lst0::Vector{String}
    lst1::Vector{String}
    lst2::Vector{String}
  end
end

@Uniontype Comment begin
  @Record COMMENT begin
    annotation_::Option{String}
    comment::Option{String}
  end
end

struct TEST2{T0 <: String}
  lst0::Vector{T0}
  lst1::Vector{T0}
  lst2::Vector{T0}
end

struct TEST4{T0 <: String, T1 <: String, T2 <: String, T3 <: String}
  a::T0
  lst0::List{T1}
  lst1::List{T2}
  lst2::List{T3}
end

@testset "Complex structure test" begin
  @testset "Testing list of complex types" begin
    local lst::List{Complex} = list(COMPLEX(0., 0.), COMPLEX(0., 0.), COMPLEX(0., 0.))
    @test length(lst) == 3
    @test listHead(lst) == COMPLEX(0., 0.)
    @test listLength(listReverse(lst)) == 3
    local lst2::List{Complex} = COMPLEX(0., 0.) <| lst
    @test length(lst2) == 4
    local lst3::List{Complex} = listAppend(lst, lst2)
    @test length(lst3) == 7
  end
  @testset "Testing arrays of complex types" begin
    #=Array of Complex elements to a List of Complex elements=#
    local A::Array{Complex} = arrayCreate(5, COMPLEX(0., 0.))
    @test length(A) == 5
    local L::List{Complex} = arrayList(A)
    @test length(L) == 5
  end
  @testset "Test even more complex (Uniontype with abstract containers)" begin
    a = COMPLEX(1., 2.)
    tst = EVENMORECOMPLEX(list(a))    
    @test length(tst.lst) == 1
    tst = EVENMORECOMPLEX(list(COMPLEX(1., 2.), COMPLEX_INT(1,1)))
    @test length(tst.lst) == 2
    tst = EVENMORECOMPLEXVECTOR([COMPLEX(1., 2.), COMPLEX(1., 2.)])
    @test length(tst.lst) == 2
    tst = INNERVECTORS("foo", ["FOO"], String[], String[])
    tst = INNERLISTS("foo", list("FOO"), Nil{String}(), Nil{String}())
    tst = COMMENT(NONE(), NONE())
  end
end

@testset "Testing array copy" begin
  arr2 = arrayCopy(arr)
  @test arrayLength(arr2) == 3
end

@testset "Testing tick()" begin
  #= Testing tick =#
  @test resetTick() == 0
  @test tick() == 1
  @test tick() == 2
  @test tick() == 3
end

@testset "Testing the Optional type" begin

  @test begin
    try
      let
        anOpt::Option{Integer} = SOME(4)
        bOpt::Option{Integer} = NONE()
        cOpt::Option{Any} = SOME(4)
      end
      true
    catch
      false
    end
  end

  struct foo1
    a::Any
  end

  struct bar2
    a::Any
    b::Any
  end

  struct baz3
    a::Any
    b::Any
    c::Any
  end

  a = NONE()
  @test 0 == @match a begin
    bar2(__) => 2
    foo1(a=7) => 3
    bar2(__) => 5
    bar2(a=1, b=2) => 6
    foo1(__) => 1
    #= We should match the wildcard =#
    _ => 0
  end

  struct optionalFoo
    a::Option{Integer}
    b::Option{Integer}
    c::Option{Integer}
  end

  try
    @test 0 == begin
      a = optionalFoo(NONE(), NONE(), NONE())
      @match a begin
        optionalFoo(NONE(), NONE(), NONE()) => 0
        _ => 1
      end
    end
  catch
    false
  end

  aa = optionalFoo(SOME(1), NONE(), NONE())
  cc = optionalFoo(NONE(), SOME(2), NONE())
  dd = optionalFoo(NONE(), NONE(), SOME(3))
  ee = optionalFoo(SOME(1), SOME(2), SOME(3))

  @test 1 == @match aa begin
    optionalFoo(SOME(2), _, _) => 2
    _ => 1
  end

  @test 1 == @match aa begin
    optionalFoo(SOME(1), _, _) => 1
    _ => 1
  end

  @test 1 == @match cc begin
    optionalFoo(_, _, _) => 1
    _ => 2
  end

  @test 2 == @match ee begin
    optionalFoo(SOME(2), _, _) => 1
    optionalFoo(__) => 2
    _ => 3
  end

  struct optionalBar
    a::Option{Integer}
  end


  a = optionalBar(NONE())
  b = optionalBar(SOME(1))

  @test 2 == @match a begin
    optionalBar(SOME(1)) => 1
    optionalBar(NONE()) => 2
  end

  @test 1 == @match b begin
    optionalBar(NONE()) => 2
    optionalBar(SOME(1)) => 1
  end

  @test 4 == @match ee begin
    optionalFoo(SOME(1), NONE(), NONE()) => 1
    optionalFoo(NONE(), SOME(2), NONE()) => 2
    optionalFoo(NONE(), NONE(), SOME(3)) => 3
    optionalFoo(SOME(1), SOME(2), SOME(3)) => 4
    _ => 4
  end

  @testset "Testing String for MetaModelica" begin
    @test "AB" == "A" + "B"
  end

  @testset "Testing MetaModelica assignment semantics" begin
    struct A
      a::Any
    end
    struct B
      b::Any
    end
    struct C
      c::Any
    end
    nested = A(B(C(1)))
    @assign nested.a.b.c = 4
    @test nested.a.b.c == 4
    @assign a = 4
    @test a == 4
    @assign simple = 4
    @test simple == 4
  end

end #=End runtime tests=#
end #=End module=#
