#=
The MetaModelica runtime. Partly automatically generated by the transpiler
Functions that are named   #= Defined in the runtime =#
are defined in the C runtime in the compiler and interfaces Boehm GC.
These functions should be remimplemented here or removed  all together =#

struct MetaModelicaGeneralException <: MetaModelicaException
  msg
end

"""
SOME
Optional with a value T
"""
struct SOME{T}
  data::T
end

"""The optional type is defined as the Union of SOME{T} and the Nothing type. """
const Option{T} = Union{SOME{T}, Nothing}

""" NONE is defined as nothing. """
NONE() = Nothing()

Base.convert(::Type{Option{S}}, x::SOME{T})  where {S, T <: S} = let
  SOME{S}(convert(S, x.data))
end

Base.convert(::Type{Option{T}}, nothing) where {T} = let
  Nothing()
end

""" Identity case """
Base.convert(::Type{Union{Nothing, SOME{T}}}, x::Union{Nothing, SOME{T}}) where {T} = let
  x
end

Base.convert(::Type{Union{Nothing, SOME{S}}}, x::SOME{S}) where{S} = let
  x
end

""" Logically combine two Booleans with 'and' operator """
function boolAnd(b1::Bool, b2::Bool)::Bool
  b = b1 && b2
end

""" Logically combine two Booleans with 'or' operator """
function boolOr(b1::Bool, b2::Bool)::Bool
  b = b1 || b2
end

""" Logically invert Boolean value using 'not' operator """
function boolNot(b::Bool)::Bool
  nb = ! b
end

""" Compares two Booleans """
function boolEq(b1::Bool, b2::Bool)::Bool
  b = b1 == b2
end

""" Returns \\\"true\\\" or \\\"false\\\" string """
function boolString(b::Bool)::String
  str = if (b) "true" else "false" end
end

""" Adds two Integer values """
function intAdd(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local i::ModelicaInteger
  i = i1 + i2
end

""" Subtracts two Integer values """
function intSub(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local i::ModelicaInteger
  i = i1 - i2
end

""" Multiplies two Integer values """
function intMul(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local i::ModelicaInteger
  i = i1 * i2
end

""" Divides two Integer values """
function intDiv(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local i::ModelicaInteger
  i = div(i1, i2)
end

""" Calculates remainder of Integer division i1/i2 """
function intMod(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local i::ModelicaInteger
  i = mod(i1, i2)
end

""" Returns the bigger one of two Integer values """
function intMax(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local i::ModelicaInteger
  i = max(i1, i2)
end

""" Returns the smaller one of two Integer values """
function intMin(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local i::ModelicaInteger
  i = min(i1, i2)
end

""" Returns the absolute value of Integer i """
function intAbs(i::ModelicaInteger)::ModelicaInteger
  local oi::ModelicaInteger
  oi = abs(i)
end

""" Returns negative value of Integer i """
function intNeg(i::ModelicaInteger)::ModelicaInteger
  local oi::ModelicaInteger
  oi = -i
end

""" Returns whether Integer i1 is smaller than Integer i2 """
function intLt(i1::ModelicaInteger, i2::ModelicaInteger)::Bool
  local b::Bool
  b = i1 < i2
end

""" Returns whether Integer i1 is smaller than or equal to Integer i2 """
function intLe(i1::ModelicaInteger, i2::ModelicaInteger)::Bool
  local b::Bool

  b = i1 <= i2
  b
end

""" Returns whether Integer i1 is equal to Integer i2 """
function intEq(i1::ModelicaInteger, i2::ModelicaInteger)::Bool
  local b::Bool

  b = i1 == i2
  b
end

""" Returns whether Integer i1 is not equal to Integer i2 """
function intNe(i1::ModelicaInteger, i2::ModelicaInteger)::Bool
  local b::Bool

  b = i1 != i2
  b
end

""" Returns whether Integer i1 is greater than or equal to Integer i2 """
function intGe(i1::ModelicaInteger, i2::ModelicaInteger)::Bool
  local b::Bool

  b = i1 >= i2
  b
end

""" Returns whether Integer i1 is greater than Integer i2 """
function intGt(i1::ModelicaInteger, i2::ModelicaInteger)::Bool
  local b::Bool
  b = i1 > i2
  b
end

""" Returns bitwise inverted Integer number of i """
function intBitNot(i::ModelicaInteger)::ModelicaInteger
  local o::ModelicaInteger = ~i
  o
end

""" Returns bitwise \'and\' of Integers i1 and i2 """
function intBitAnd(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local o::ModelicaInteger = i1 & i2
  o
end

""" Returns bitwise 'or' of Integers i1 and i2 """
function intBitOr(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local o::ModelicaInteger = i1 | i2
  o
end

""" Returns bitwise 'xor' of Integers i1 and i2 """
function intBitXor(i1::ModelicaInteger, i2::ModelicaInteger)::ModelicaInteger
  local o::ModelicaInteger = i1 ⊻ i2
  o
end

""" Returns bitwise left shift of Integer i by s bits """
function intBitLShift(i::ModelicaInteger, s::ModelicaInteger)::ModelicaInteger
  local o::ModelicaInteger = i << i
  o
end

""" Returns bitwise right shift of Integer i by s bits """
function intBitRShift(i::ModelicaInteger, s::ModelicaInteger)::ModelicaInteger
  local o::ModelicaInteger = i >> s
  o
end

""" Converts Integer to Real """
function intReal(i::ModelicaInteger)::ModelicaReal
  Float64(i)
end

""" Converts Integer to String """
function intString(i::ModelicaInteger)::String
  string(i)
end

function realAdd(r1::ModelicaReal, r2::ModelicaReal)::ModelicaReal
  local r::ModelicaReal

  r = r1 + r2
  r
end

function realSub(r1::ModelicaReal, r2::ModelicaReal)::ModelicaReal
  local r::ModelicaReal

  r = r1 - r2
  r
end

function realMul(r1::ModelicaReal, r2::ModelicaReal)::ModelicaReal
  local r::ModelicaReal

  r = r1 * r2
  r
end

function realDiv(r1::ModelicaReal, r2::ModelicaReal)::ModelicaReal
  local r::ModelicaReal

  r = r1 / r2
  r
end

function realMod(r1::ModelicaReal, r2::ModelicaReal)::ModelicaReal
  local r::ModelicaReal

  r = mod(r1, r2)
  r
end

function realPow(r1::ModelicaReal, r2::ModelicaReal)::ModelicaReal
  local r::ModelicaReal

  r = r1 ^ r2
  r
end

function realMax(r1::ModelicaReal, r2::ModelicaReal)::ModelicaReal
  local r::ModelicaReal
  r = max(r1, r2)
end

function realMin(r1::ModelicaReal, r2::ModelicaReal)::ModelicaReal
  local r::ModelicaReal
  r = min(r1, r2)
end

function realAbs(x::ModelicaReal)::ModelicaReal
  local y::ModelicaReal
  y = abs(x)
end

function realNeg(x::ModelicaReal)::ModelicaReal
  local y::ModelicaReal
  y = -x
end

function realLt(x1::ModelicaReal, x2::ModelicaReal)::Bool
  local b::Bool
  b = x1 < x2
end

function realLe(x1::ModelicaReal, x2::ModelicaReal)::Bool
  local b::Bool
  b = x1 <= x2
end

function realEq(x1::ModelicaReal, x2::ModelicaReal)::Bool
  local b::Bool
  b = x1 == x2
end

function realNe(x1::ModelicaReal, x2::ModelicaReal)::Bool
  local b::Bool
  b = x1 != x2
end

function realGe(x1::ModelicaReal, x2::ModelicaReal)::Bool
  local b::Bool

  b = x1 >= x2
  b
end

function realGt(x1::ModelicaReal, x2::ModelicaReal)::Bool
  local b::Bool

  b = x1 > x2
  b
end

function realInt(r::ModelicaReal)::ModelicaInteger
  local i::ModelicaInteger
  i = Integer(trunc(r))
end

function realString(r::ModelicaReal)::String
  local str::String
  string(str)
end

function stringCharInt(ch::String)::ModelicaInteger
  local i::ModelicaInteger = Int64(ch[1])
  i
end

function intStringChar(i::ModelicaInteger)::String
  local ch::String = string(Char(i))
  ch
end

function stringInt(str::String)::ModelicaInteger
  local i::ModelicaInteger = Int64(str)
  i
end

""" This function fails unless the whole string can be consumed by strtod without
setting errno. For more details, see man 3 strtod """
function stringReal(str::String)::ModelicaReal
  local r::ModelicaReal = parse(Float64, str)
  r
end

""" O(str) """
function stringListStringChar(str::String)::List{String}
  local chars::List{String} = nil
  for i in length(chars):-1:1
    chars = _cons(string(str[i]), chars)
  end
  chars
end

""" O(str) """
function stringAppendList(strs::List)::String
  local str::String = ""
  for n in strs
    str = str + n
  end
  str
end

""" O(str)
  Takes a list of strings and a string delimiter and appends all
  list elements with the string delimiter inserted between elements.
  Example: stringDelimitList({\"x\",\"y\",\"z\"}, \", \") => \"x, y, z\"
"""
function stringDelimitList(strs::List{String}, delimiter::String)::String
  local str::String = ""
  for n in strs
    if isempty(str)
      str = n
    else
      str = str + delimiter + n
    end
  end
  str
end

function stringDelimitList(strs::List{Any}, delimiter::String)::String
  local str::String = ""
  for n in strs
    if isempty(str)
      str = n
    else
      str = str + delimiter + n
    end
  end
  str
end

""" O(1) """
function stringLength(str::String)::ModelicaInteger
  length(str)
end

""" O(1) """
function stringEmpty(str::String)::Bool
  local isEmpty::Bool
  isEmpty = stringLength(str) == 0
end

""" O(1) """
function stringGet(str::String, index::ModelicaInteger)::ModelicaInteger
  if index < 0
    println("stringGet: index < 0!")
    fail()
  end
  str[index]
end

""" O(1) """
function stringGetStringChar(str::String, index::ModelicaInteger)::String
  if index < 0
    println("stringGetStringChar: index < 0!")
    fail()
  end
  local ch::String = string(str[index])
  ch
end

""" O(n) """
function stringUpdateStringChar(str::String, newch::String, index::ModelicaInteger)::String
  local news::String = str
  if index < 0
    println("stringUpdateStringChar: index < 0!")
    fail()
  end
  news[index] = newch[1]
  news
end

""" O(s1+s2) """
function stringAppend(s1::String, s2::String)::String
  s1 * s2
end

""" O(N) """
function stringEq(s1::String, s2::String)::Bool
  s1 == s2
end

""" O(N) """
function stringEqual(s1::String, s2::String)::Bool
  s1 == s2
end

function stringCompare(s1::String, s2::String)::ModelicaInteger
  res = cmp(s1, s2)
  if res < 0
    return -1
  end
  if res > 0
    return 1
  end
  return 0
end

function myhash(s::String)::ModelicaInteger
  local h::ModelicaInteger = mod(hash(s), typemax(ModelicaInteger))
  h
end

function stringHash(str::String)::ModelicaInteger
  local h::ModelicaInteger = ModelicaInteger(myhash(str))
  h
end

#= TODO: Defined in the runtime =#
function stringHashDjb2(str::String)::ModelicaInteger
  local h::ModelicaInteger = ModelicaInteger(myhash(str))
  h
end

""" Does hashing+modulo without intermediate results. """
function stringHashDjb2Mod(str::String, m::ModelicaInteger)::ModelicaInteger
  local h::ModelicaInteger = mod(ModelicaInteger(myhash(str)), m)
  h
end

function stringHashSdbm(str::String)::ModelicaInteger
  local h::ModelicaInteger = ModelicaInteger(myhash(str))
  h
end

function substring(str::String, start #=start index, first character is 1 =#::ModelicaInteger, stop #= stop index, first character is 1 =#::ModelicaInteger)::String
  if start < 0
    println("substring: start < 0!")
    fail()
  end
  local out = str[start:stop]
  out
end

""" O(1) """
function arrayLength(arr::Array{T})::ModelicaInteger where {T}
  length(arr)
end

""" O(1) """
function arrayEmpty(arr::Array{A})::Bool where {A}
  length(arr) == 0
end

""" O(1) """
function arrayGet(arr::Array{A}, index::ModelicaInteger)::A where {A}
  if index < 0
    println("arrayGet: index < 0!")
    fail()
  end
  arr[index]
end

""" O(size) """
function arrayCreate(size::ModelicaInteger, initialValue::A)::Array{A} where {A}
  fill(initialValue, size)
end

""" Creates an array out of a List """
function arrayList(arr::Array{T})::List{T} where {T}
  local lst::List{T} = nil
  for i in length(arr):-1:1
    lst = Cons{T}(arr[i], lst)
  end
  lst
end

""" O(n) """
function listArray(lst::List{T})::Array{T} where {T}
  local arr::Array{T} = []
  for i in lst
    push!(arr, i)
  end
  arr
end

""" O(1) """
function arrayUpdate(arr::Array{A}, index::ModelicaInteger, newValue::B)::Array{A} where {A,B}
  local newArray #= same as the input array; used for folding =#::Array{A} = arr
  #if !(A <: B)
  #  println("!(A<:B)")
  #  @show A
  #  @show B
  #end
  if index < 0
    println("arrayUpdate: index < 0!")
    fail()
  end
  newArray[index] = newValue
  #= Defined in the runtime =#
  newArray #= same as the input array; used for folding =#
end

""" O(n) """
function arrayCopy(arr::Array{A})::Array{A} where {A}
  copy(arr)
end

""" Appends arr2 to arr1. O(length(arr1) + length(arr2)).
Note that this operation is *not* destructive, i.e. a new array is created. """
function arrayAppend(arr1::Array{A}, arr2::Array{A})::Array{A} where {A}
  local arr::Array{A}

  #= Defined in the runtime =#
  arr
end

""" Returns the string representation of any value.
Rather slow; only use this for debugging! """
function anyString(a::A)::String where {A}
  dump(a)
end

""" print(anyString(a)), but to stderr """
function printAny(a::A) where {A}
  println(dump(a))
end

""" For RML compatibility """
function debug_print(str::String, a::A) where {A}
  #= Defined in the runtime =#
  println(str)
  @show a
end

global tickCounter = 0
function tick()::ModelicaInteger
  global tickCounter = tickCounter + 1
end

function equality(a1::A1, a2::A2) where {A1,A2}
  #= Defined in the runtime =#
  if !valueEq(a1, a2)
    fail()
  end
end

# cannot use nothing in the globalRoots array
# as NONE() is nothing so we use the struct below
# to signal when an element is not set

""" Sets the index of the root variable with index 1..1024
This is a global mutable value and should be used sparingly.
You are recommended not to use "missing" the runtime system treats this values as uninitialized and fail getGlobalRoot later on.
"""
global globalRoots = Array{Any,1}(missing, 1024)

function setGlobalRoot(index::ModelicaInteger, value::T) where {T}
  if index > 1023 || index < 0
    fail()
  end
  globalRoots[index+1] = value
end

function getGlobalRoot(index::ModelicaInteger)
  if index > 1023 || index < 0
    fail()
  end
  val = globalRoots[index+1]
  if ismissing(val)
    fail()
  end
  val
end

""" The return-value is compiler-dependent on the runtime implementation of
boxed values. The number of bits reserved for the constructor is generally
between 6 and 8 bits. """
function valueConstructor(value::A)::ModelicaInteger where {A}
  # hack! hack! hack!
  local ctor::ModelicaInteger = myhash(string(typeof(value)))
  ctor
end

""" The number of slots a boxed value has. This is dependent on sizeof(void*)
on the architecture in question. """
function valueSlots(value::A)::ModelicaInteger where {A}
  local slots::ModelicaInteger = 0
  try
    slots = nfields(value)
  catch ex
    # do nothing
  end
  slots
end

""" Structural equality """
function valueEq(a1::A, a2::B)::Bool where {A, B}
  local b::Bool =
  @match (a1, a2) begin
    (SOME(x1), SOME(x2)) => valueEq(x1, x2)
    (_, _) => a1 === a2
  end
  b
end

""" a1 > a2 """
function valueCompare(a1::A, a2::A)::ModelicaInteger where {A}
  local i::ModelicaInteger =
    if valueConstructor(a1) < valueConstructor(a2)
      -1
    elseif valueConstructor(a1) > valueConstructor(a2)
      1
    else
      0
    end
  i #= -1, 0, 1 =#
end

function valueHashMod(value::A, mod::ModelicaInteger)::ModelicaInteger where {A}
  local h::ModelicaInteger = mod(ModelicaInteger(myhash(string(value))), m)
  h
end

""" This is a very fast comparison of two values which only checks if the pointers are equal. """
function referenceEq(a1::A1, a2::A2)::Bool where {A1, A2}
  #TODO: Should be like this?
  a1===a2
end

""" Returns the pointer address of a reference as a hexadecimal string that can
be used for debugging. """
function referencePointerString(ref::A)::String where {A}
  local str::String
  @assert false "not implemented"
  str
end

""" Use the diff to compare two time samples to each other. Not very accurate. """
function clock()::ModelicaReal
  local t::ModelicaReal
  @assert false "not implemented"
  t
end

""" Returns true if the input is NONE() """
function isNone(opt::Option{A})::Bool where {A}
  (opt==nothing) # isa(opt, NONE))
end

""" Returns true if the input is SOME() """
function isSome(opt::Option{A})::Bool where{A}
  isa(opt, SOME)
end

function listStringCharString(strs::List{String})::String
  local str::String
  @assert false "not implemented"
  str
end

function stringCharListString(strs::List{String})::String
  local str::String = ""
  for s in strs
    str = str + s
  end
  str
end

function fail()
  throw(MetaModelicaGeneralException("Runtime defined generic Meta Modelica failure"))
end

""" Sets the stack overflow signal to the given value and returns the old one """
function setStackOverflowSignal(inSignal::Bool)::Bool
  local outSignal::Bool

  outSignal = inSignal
  outSignal
end

function referenceDebugString(functionSymbol::A)::String where {A}
  local name::String
  @assert false "not implemented"
  name
end

""" TODO: I am far from sure that this will fly.. in Julia. The code generated from the transpiler is correct however"""
function isPresent(ident::T)::Bool where {T}
  local b::Bool
  b = true
  b
end

#= The Info attribute provides location information for elements and classes. =#
@Uniontype SourceInfo begin
  @Record SOURCEINFO begin
    fileName #= fileName where the class is defined in =#::String
    isReadOnly #= isReadOnly : (true|false). Should be true for libraries =#::Bool
    lineNumberStart #= lineNumberStart =#::ModelicaInteger
    columnNumberStart #= columnNumberStart =#::ModelicaInteger
    lineNumberEnd #= lineNumberEnd =#::ModelicaInteger
    columnNumberEnd #= columnNumberEnd =#::ModelicaInteger
    lastModification #= mtime in stat(2), stored as a double for increased precision on 32-bit platforms =#::ModelicaReal
  end
end


SOURCEINFO(fileName::String, isReadOnly::Bool, lineNumberStart::ModelicaInteger, columnNumberSTart::ModelicaInteger, lineNumberEnd::ModelicaInteger, columnNumberEnd::ModelicaInteger) = let
  #=No source info=#
  SOURCEINFO(fileName, isReadOnly, lineNumberStart, columnNumberSTart, lineNumberEnd, columnNumberEnd, 0.0)
end

function sourceInfo()::SourceInfo
  local info::SourceInfo
  #= Defined in the runtime =#
  SOURCEINFO("", true, 1, 2, 3, 4, 0.0)
end

Base.:+(x::String, y::String) = let
  x * y
end

""" Imports and prints if the import is sucessful """
macro importDBG(moduleName)
  quote
    import $moduleName
    x = string(@__MODULE__)
    y = string($(esc(moduleName)))
    println("Importing " * y  * " in " * x)
  end
end

function getInstanceName()::String
  "__NOT_IMPLEMENTED__"
end

function StringFunction(i::Int64)::String
  intString(i)
end

function StringFunction(r::Float64)::String
  realString(r)
end
