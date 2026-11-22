#=
  Pins the names `using MetaModelica` and `using MetaModelica.Dangerous` export.
  A new export is a decision: add it here and to the docs in the same commit.
=#
module ExportTests

using MetaModelica
using Test

const EXPORTED = split("""
<| => @CUniontype @ExtendedAnonFunction @ExtendedFunction @Mutable_Uniontype @Record @T_Uniontype @Uniontype
@UniontypeDecl @assign @cheap_throws @closure @do_threaded_for @fastmatch @match @matchcontinue
@nospecialized @registerVariants @shouldFail @unsafematch Cons List MatchFailure ModelicaInteger ModelicaReal NONE Nil Option
SOME String StringFunction _cons _listAppend anyString arrayAppend arrayCopy
arrayCreate arrayEmpty arrayGet arrayLength arrayList arrayUpdate boolAnd boolEq boolNot boolOr boolString
clock compacted_tag_info cons debug_print equality fail getGlobalRoot getInstanceName intAbs intAdd intBitAnd
intBitLShift intBitNot intBitOr intBitRShift intBitXor intDiv intEq intGe intGt intLe intLt intMax intMin
intMod intMul intNe intNeg intReal intString intStringChar intSub isNone isPresent isSome isvariant list
listAppend listArray listDelete listEmpty listGet listHead listLength listMember listRest listReverse
listStringCharString mm_throw nil printAny realAbs realAdd realDiv realEq realGe realGt realInt realLe realLt
realMax realMin realMod realMul realNe realNeg realPow realString realSub referenceDebugString referenceEq
referencePointerString resetTick setGlobalRoot setStackOverflowSignal stringAppend
stringAppendList stringCharInt stringCharListString stringCompare stringDelimitList stringEmpty stringEq
stringEqual stringGet stringGetStringChar stringHash stringHashDjb2 stringHashDjb2Mod stringHashSdbm
stringInt stringLength stringListStringChar stringReal stringUpdateStringChar substring tick valueCompare
valueConstructor valueEq valueHashMod valueSlots variantof with_cheap_throws
""")

const DANGEROUS = split("""
arrayCreateNoInit arrayGetNoBoundsChecking arrayUpdateNoBoundsChecking listArrayLiteral listGetFirstAsPtr
listReverseInPlace listSetFirst listSetRest stringGetNoBoundsChecking unsafe_pointer_from_objref
""")

@testset "exported names" begin
  @test sort!(String.(filter(!=(:MetaModelica), names(MetaModelica)))) == sort!(String.(EXPORTED))
  @test sort!(String.(filter(!=(:Dangerous), names(MetaModelica.Dangerous)))) == sort!(String.(DANGEROUS))
  @test !(:eval in names(MetaModelica.Dangerous))
end

end
