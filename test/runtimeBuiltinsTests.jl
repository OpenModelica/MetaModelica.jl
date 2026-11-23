#= The MetaModelica builtins of metaRuntime.jl and MetaModelica.Dangerous, one small check each. =#
module RuntimeBuiltinsTests

using MetaModelica
using MetaModelica.Dangerous
using Test

struct Pair2
  a::Int
  b::String
end

mutable struct Box
  x::Int
end

#= Builtins that print a message before they fail: keep the test output clean. =#
quiet(f::Function) = redirect_stdout(f, devnull)

@testset "Boolean builtins" begin
  @test boolAnd(true, true) && !boolAnd(true, false)
  @test boolOr(false, true) && !boolOr(false, false)
  @test boolNot(false) && !boolNot(true)
  @test boolEq(true, true) && !boolEq(true, false)
  @test boolString(true) == "true" && boolString(false) == "false"
end

@testset "Integer builtins" begin
  @test intAdd(2, 3) == 5 && intSub(2, 3) == -1 && intMul(2, 3) == 6
  @test intDiv(7, 2) == 3 && intDiv(-7, 2) == -3
  @test intMod(7, 3) == 1 && intMod(-7, 3) == 2
  @test intMax(2, 3) == 3 && intMin(2, 3) == 2
  @test intAbs(-4) == 4 && intNeg(4) == -4
  @test intLt(1, 2) && intLe(2, 2) && intEq(2, 2) && intNe(1, 2) && intGe(2, 2) && intGt(3, 2)
  @test !intLt(2, 1) && !intEq(1, 2) && !intGt(2, 3)
  @test intBitNot(0) == -1
  @test intBitAnd(0b1100, 0b1010) == 0b1000
  @test intBitOr(0b1100, 0b1010) == 0b1110
  @test intBitXor(0b1100, 0b1010) == 0b0110
  @test intBitLShift(1, 4) == 16 && intBitRShift(16, 4) == 1
  @test intReal(3) === 3.0
  @test intString(42) == "42"
  @test intStringChar(65) == "A" && stringCharInt("A") == 65
end

@testset "Real builtins" begin
  @test realAdd(1.5, 2.0) == 3.5 && realSub(1.5, 2.0) == -0.5
  @test realMul(1.5, 2.0) == 3.0 && realDiv(3.0, 2.0) == 1.5
  @test realMod(7.5, 2.0) == 1.5 && realPow(2.0, 3.0) == 8.0
  @test realMax(1.0, 2.0) == 2.0 && realMin(1.0, 2.0) == 1.0
  @test realAbs(-2.5) == 2.5 && realNeg(2.5) == -2.5
  @test realLt(1.0, 2.0) && realLe(2.0, 2.0) && realEq(2.0, 2.0) && realNe(1.0, 2.0)
  @test realGe(2.0, 2.0) && realGt(3.0, 2.0) && !realGt(2.0, 3.0)
  @test realString(2.5) == "2.5"
  @test StringFunction(7) == "7" && StringFunction(0.5) == "0.5"
end

@testset "String builtins" begin
  @test stringListStringChar("abc") == list("a", "b", "c")
  @test stringListStringChar("") === nil
  @test stringAppendList(list("a", "b", "c")) == "abc"
  @test stringDelimitList(list("a", "b", "c"), ", ") == "a, b, c"
  @test stringDelimitList(list("a"), ", ") == "a"
  @test stringDelimitList(nil, ", ") == ""
  @test stringDelimitList(["x", "y"], "-") == "x-y"
  @test stringDelimitList(String[], "-") == ""
  @test stringLength("abc") == 3 && stringEmpty("") && !stringEmpty("a")
  @test stringGet("abc", 2) == 'b'
  @test stringGetStringChar("abc", 3) == "c"
  @test stringUpdateStringChar("abc", "X", 2) == "aXc"
  @test stringAppend("ab", "cd") == "abcd"
  @test stringEq("a", "a") && stringEqual("a", "a") && !stringEq("a", "b")
  @test stringCompare("a", "b") == -1 && stringCompare("b", "a") == 1 && stringCompare("a", "a") == 0
  @test stringHash("abc") == stringHash("abc") && stringHash("abc") >= 0
  @test stringHashSdbm("abc") == stringHash("abc")
  @test substring("hello", 2, 4) == "ell"
  @test listStringCharString(list("a", "b")) == "ab"
  @test_throws MetaModelica.MetaModelicaGeneralException quiet(() -> stringGetStringChar("abc", -1))
  @test_throws MetaModelica.MetaModelicaGeneralException quiet(() -> stringUpdateStringChar("abc", "X", -1))
  @test_throws MetaModelica.MetaModelicaGeneralException quiet(() -> substring("abc", -1, 2))
end

@testset "Array and list builtins" begin
  @test_throws MetaModelica.MetaModelicaGeneralException quiet(() -> arrayGet([1, 2], -1))
  @test listArray(nil) == []
  local a = listArray(list(1, 2), Float64)
  @test a == [1.0, 2.0] && eltype(a) == Float64
  @test listArray(nil, Int) == Int[] && eltype(listArray(nil, Int)) == Int
  local b = arrayAppend([1, 2], [3])
  @test b == [1, 2, 3]
  @test arrayAppend(Int[], Int[]) == Int[]
end

@testset "Value builtins" begin
  @test valueConstructor(Pair2(1, "a")) == valueConstructor(Pair2(2, "b"))
  @test valueConstructor(Pair2(1, "a")) != valueConstructor(1)
  @test valueSlots(Pair2(1, "a")) == 2 && valueSlots(nothing) == 0
  @test valueEq(SOME(1), SOME(1)) && !valueEq(SOME(1), SOME(2))
  @test valueEq(1, 1) && !valueEq(1, 2)
  @test valueCompare(1, 2) == 0
  local m = valueHashMod("abc", 7)
  @test 0 <= m < 7 && m == valueHashMod("abc", 7)
  local x = Box(1)
  @test referenceEq(x, x) && !referenceEq(x, Box(1))
  @test startswith(referencePointerString(x), "0x")
  @test referencePointerString(x) == referencePointerString(x)
  @test referencePointerString(x) != referencePointerString(Box(1))
  @test referenceDebugString(intAdd) == "intAdd"
  @test isNone(NONE()) && !isNone(SOME(1))
  @test isSome(SOME(1)) && !isSome(NONE())
  equality(SOME(2), SOME(2))
  @test_throws MetaModelica.MetaModelicaGeneralException equality(1, 2)
  @test occursin("Pair2", anyString(Pair2(1, "a")))
  @test occursin("b: String \"a\"", anyString(Pair2(1, "a")))
end

@testset "Global roots" begin
  setGlobalRoot(5, "five")
  @test getGlobalRoot(5) == "five"
  setGlobalRoot(5, missing)
  @test_throws MetaModelica.MetaModelicaGeneralException getGlobalRoot(5)
  @test_throws MetaModelica.MetaModelicaGeneralException setGlobalRoot(1024, 1)
  @test_throws MetaModelica.MetaModelicaGeneralException setGlobalRoot(-1, 1)
  @test_throws MetaModelica.MetaModelicaGeneralException getGlobalRoot(1024)
end

@testset "Runtime misc" begin
  local t1 = clock()
  local t2 = clock()
  @test t1 isa Float64 && t2 >= t1
  @test setStackOverflowSignal(true) && !setStackOverflowSignal(false)
  @test isPresent(1)
  @test getInstanceName() == MetaModelica.NOT_IMPLEMENTED_MSG
  @test occursin("runtimeBuiltinsTests.jl", MetaModelica.@instanceName)
  #= Debug printers: output goes to stdout or stderr, the result is nothing. =#
  local out = mktemp() do path, io
    redirect_stdout(() -> debug_print("label", 1), io)
    flush(io)
    read(path, String)
  end
  @test occursin("label", out) && occursin("a = 1", out)
  @test redirect_stderr(() -> printAny(1), devnull) === nothing
  @test_throws MetaModelica.MetaModelicaGeneralException fail("a message")
end

@testset "MetaModelica.Dangerous" begin
  local v = [1, 2, 3]
  @test arrayGetNoBoundsChecking(v, 2) == 2
  @test arrayUpdateNoBoundsChecking(v, 2, 20) === v && v[2] == 20
  local u = arrayCreateNoInit(3, 0)
  @test length(u) == 3 && eltype(u) == Int
  @test stringGetNoBoundsChecking("abc", 2) == 'b'
  local x = Box(1)
  @test unsafe_pointer_from_objref(x) == pointer_from_objref(x)
end

end #= RuntimeBuiltinsTests =#
