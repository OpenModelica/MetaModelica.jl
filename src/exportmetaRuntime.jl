#=
  The MetaModelica builtin functions and runtime helpers exported by `using MetaModelica`.
  Grouped by the prefix of the name. Add new exports to the group they belong to.
  test/exportTests.jl pins the exported names: a new export is a decision.
=#

#= Arrays =#
export arrayAppend, arrayCopy, arrayCreate, arrayEmpty, arrayGet, arrayLength, arrayList, arrayUpdate

#= Booleans =#
export boolNot, boolAnd, boolEq, boolOr, boolString

#= Integers =#
export intAbs, intAdd, intBitLShift, intBitNot, intBitAnd, intBitOr, intBitRShift, intBitXor, intDiv, intEq, intGe, intGt, intLe, intLt, intMax, intMin, intMod, intMul, intNe, intNeg, intReal, intString, intStringChar, intSub

#= Reals =#
export realAbs, realAdd, realDiv, realEq, realGe, realGt, realInt, realLe, realLt, realMax, realMin, realMod, realMul, realNe, realNeg, realPow, realString, realSub

#= Strings =#
export stringAppend, stringAppendList, stringCharInt, stringCharListString, stringCompare, stringDelimitList, stringEmpty, stringEqual, stringEq, stringGet, stringGetStringChar, stringHash, stringHashDjb2, stringHashDjb2Mod, stringHashSdbm, stringInt, stringLength, stringListStringChar, stringReal, stringUpdateStringChar

#= Lists =#
export listAppend, listArray, listDelete, listEmpty, listGet, listHead, listLength, listMember, listRest, listReverse, listStringCharString

#= Values =#
export valueCompare, valueConstructor, valueEq, valueHashMod, valueSlots

#= References =#
export referenceDebugString, referenceEq, referencePointerString

#= Other builtins and helpers =#
export anyString, clock, cons, debug_print, equality, fail, getGlobalRoot, isNone, isPresent, isSome, printAny, setGlobalRoot, setStackOverflowSignal, String, substring, tick, resetTick, _listAppend, getInstanceName, StringFunction
