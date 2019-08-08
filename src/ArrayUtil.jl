#= /*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
* c/o Linköpings universitet, Department of Computer and Information Science,
* SE-58183 Linköping, Sweden.
*
* All rights reserved.
*
* THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
* THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
* ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
* RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
* ACCORDING TO RECIPIENTS CHOICE.
*
* The OpenModelica software and the Open Source Modelica
* Consortium (OSMC) Public License (OSMC-PL) are obtained
* from OSMC, either from the above address,
* from the URLs: http:www.ida.liu.se/projects/OpenModelica or
* http:www.openmodelica.org, and in the OpenModelica distribution.
* GNU version 3 is obtained from: http:www.gnu.org/copyleft/gpl.html.
*
* This program is distributed WITHOUT ANY WARRANTY; without
* even the implied warranty of  MERCHANTABILITY or FITNESS
* FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
* IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
*
* See the full OSMC Public License conditions for more details.
*
*/ =#

module ArrayUtil

using MetaModelica
#= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
using ExportAll
using MetaModelica.Dangerous: arrayGetNoBoundsChecking, arrayUpdateNoBoundsChecking, arrayCreateNoInit

""" Takes an array and a function over the elements of the array, which is
applied for each element.  Since it will update the array values the returned
array must have the same type, and thus the applied function must also return
the same type. """
function mapNoCopy(inArray::Array{T}, inFunc::Function)  where {T}
  local outArray::Array{T} = inArray
  for i in 1:arrayLength(inArray)
    arrayUpdate(inArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i)))
  end
  outArray
end

""" Same as arrayMapNoCopy, but with an additional arguments that's updated for
each call. """
function mapNoCopy_1(inArray::Array{T}, inFunc::Function, inArg::ArgT)  where {T, ArgT}
  local outArg::ArgT = inArg
  local outArray::Array{T} = inArray
  local e::T
  for i in 1:arrayLength(inArray)
    (e, outArg) = inFunc((arrayGetNoBoundsChecking(inArray, i), outArg))
    arrayUpdate(inArray, i, e)
  end
  (outArray, outArg)
end

function downheap(inArray::Array{<:ModelicaInteger}, n::ModelicaInteger, vIn::ModelicaInteger) ::Array{ModelicaInteger}
  local v::ModelicaInteger = vIn
  local w::ModelicaInteger = 2 * v + 1
  local tmp::ModelicaInteger
  while w < n
    if w + 1 < n
      if inArray[w + 2] > inArray[w + 1]
        w = w + 1
      end
    end
    if inArray[v + 1] >= inArray[w + 1]
      return inArray
    end
    tmp = inArray[v + 1]
    inArray[v + 1] = inArray[w + 1]
    inArray[w + 1] = tmp
    v = w
    w = 2 * v + 1
  end
  inArray
end

function heapSort(inArray::Array{<:ModelicaInteger}) ::Array{ModelicaInteger}
  local n::ModelicaInteger = arrayLength(inArray)
  local tmp::ModelicaInteger
  for v in intDiv(n, 2) - 1:(-1):0
    inArray = downheap(inArray, n, v)
  end
  for v in n:(-1):2
    tmp = inArray[1]
    inArray[1] = inArray[v]
    inArray[v] = tmp
    inArray = downheap(inArray, v - 1, 0)
  end
  inArray
end

function findFirstOnTrue(inArray::Array{T}, inPredicate::Function)  where {T}
  local outElement::Option{T}

  outElement = NONE()
  for e in inArray
    if inPredicate(e)
      outElement = SOME(e)
      break
    end
  end
  outElement
end

function findFirstOnTrueWithIdx(inArray::Array{T}, inPredicate::Function)  where {T}
  local idxOut::ModelicaInteger = -1
  local outElement::Option{T}
  local idx::ModelicaInteger = 1
  outElement = NONE()
  for e in inArray
    if inPredicate(e)
      idxOut = idx
      outElement = SOME(e)
      break
    end
    idx = idx + 1
  end
  (outElement, idxOut)
end

""" Takes an array and a list of indices, and returns a new array with the
indexed elements. Will fail if any index is out of bounds. """
function select(inArray::Array{T}, inIndices::List{ModelicaInteger})  where {T}
  local outArray::Array{T}
  local i::ModelicaInteger = 1
  outArray = arrayCreateNoInit(listLength(inIndices), inArray[1])
  for e in inIndices
    arrayUpdate(outArray, i, arrayGet(inArray, e))
    i = i + 1
  end
  outArray
end

""" Takes an array and a function over the elements of the array, which is
applied to each element. The updated elements will form a new array, leaving
the original array unchanged. """
function map(inArray::Array{TI}, inFunc::Function)  where {TI, TO}
  local outArray::Array{TO}
  local len::ModelicaInteger = arrayLength(inArray)
  local res::TO
  #=  If the array is empty, use list transformations to fix the types! =#
  if len == 0
    outArray = listArray(nil())
  else
    res = inFunc(arrayGetNoBoundsChecking(inArray, 1))
    outArray = arrayCreateNoInit(len, res)
    arrayUpdateNoBoundsChecking(outArray, 1, res)
    for i in 2:len
      arrayUpdateNoBoundsChecking(outArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i)))
    end
  end
  #=  If the array isn't empty, use the first element to create the new array.
  =#
  outArray
end

""" Takes an array, an extra arguments, and a function over the elements of the
array, which is applied to each element. The updated elements will form a new
array, leaving the original array unchanged. """
function map1(inArray::Array{TI}, inFunc::Function, inArg::ArgT)  where {TI, TO, ArgT}
  local outArray::Array{TO}
  local len::ModelicaInteger = arrayLength(inArray)
  local res::TO
  #=  If the array is empty, use list transformations to fix the types! =#
  if len == 0
    outArray = listArray(nil())
  else
    res = inFunc(arrayGetNoBoundsChecking(inArray, 1), inArg)
    outArray = arrayCreateNoInit(len, res)
    arrayUpdate(outArray, 1, res)
    for i in 2:len
      arrayUpdate(outArray, i, inFunc(arrayGetNoBoundsChecking(inArray, i), inArg))
    end
  end
  #=  If the array isn't empty, use the first element to create the new array. =#
  outArray
end

""" Applies a non-returning function to all elements in an array. """
function map0(inArray::Array{T}, inFunc::Function)  where {T}
  for e in inArray
    inFunc(e)
  end
end

""" As map, but takes a list in and creates an array from the result. """
function mapList(inList::List{TI}, inFunc::Function)  where {TI, TO}
  local outArray::Array{TO}
  local i::ModelicaInteger = 2
  local len::ModelicaInteger = listLength(inList)
  local res::TO
  if len == 0
    outArray = listArray(nil())
  else
    res = inFunc(listHead(inList))
    outArray = arrayCreateNoInit(len, res)
    arrayUpdate(outArray, 1, res)
    for e in listRest(inList)
      arrayUpdate(outArray, i, inFunc(e))
      i = i + 1
    end
  end
  outArray
end

""" Takes an array, a function, and a start value. The function is applied to
each array element, and the start value is passed to the function and
updated. """
function fold(inArray::Array{T}, inFunction::Function, inStartValue::FoldT)  where {T, FoldT}
  local outResult::FoldT = inStartValue
  for e in inArray
    outResult = inFunction(e, outResult)
  end
  outResult
end

""" Takes an array, a function, and a start value. The function is applied to
each array element, and the start value is passed to the function and
updated. """
function fold1(inArray::Array{T}, inFunction::Function, inArg::ArgT, inStartValue::FoldT)  where {T, FoldT, ArgT}
  local outResult::FoldT = inStartValue
  for e in inArray
    outResult = inFunction(e, inArg, outResult)
  end
  outResult
end

""" Takes an array, a function, a constant parameter, and a start value. The
function is applied to each array element, and the start value is passed to
the function and updated. """
function fold2(inArray::Array{T}, inFunction::Function, inArg1::ArgT1, inArg2::ArgT2, inStartValue::FoldT)  where {T, FoldT, ArgT1, ArgT2}
  local outResult::FoldT = inStartValue
  for e in inArray
    outResult = inFunction(e, inArg1, inArg2, outResult)
  end
  outResult
end

""" Takes an array, a function, a constant parameter, and a start value. The
function is applied to each array element, and the start value is passed to
the function and updated. """
function fold3(inArray::Array{T}, inFunction::Function, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inStartValue::FoldT)  where {T, FoldT, ArgT1, ArgT2, ArgT3}
  local outResult::FoldT = inStartValue
  for e in inArray
    outResult = inFunction(e, inArg1, inArg2, inArg3, outResult)
  end
  outResult
end

""" Takes an array, a function, four constant parameters, and a start value. The
function is applied to each array element, and the start value is passed to
the function and updated. """
function fold4(inArray::Array{T}, inFunction::Function, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inStartValue::FoldT)  where {T, FoldT, ArgT1, ArgT2, ArgT3, ArgT4}
  local outResult::FoldT = inStartValue
  for e in inArray
    outResult = inFunction(e, inArg1, inArg2, inArg3, inArg4, outResult)
  end
  outResult
end

""" Takes an array, a function, four constant parameters, and a start value. The
function is applied to each array element, and the start value is passed to
the function and updated. """
function fold5(inArray::Array{T}, inFunction::Function, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inStartValue::FoldT)  where {T, FoldT, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5}
  local outResult::FoldT = inStartValue
  for e in inArray
    outResult = inFunction(e, inArg1, inArg2, inArg3, inArg4, inArg5, outResult)
  end
  outResult
end

""" Takes an array, a function, four constant parameters, and a start value. The
function is applied to each array element, and the start value is passed to
the function and updated. """
function fold6(inArray::Array{T}, inFunction::Function, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6, inStartValue::FoldT)  where {T, FoldT, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6}
  local outResult::FoldT = inStartValue
  for e in inArray
    outResult = inFunction(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, outResult)
  end
  outResult
end

""" Takes an array, a function, and a start value. The function is applied to
each array element, and the start value is passed to the function and
updated, additional the index of the passed element is also passed to the function. """
function foldIndex(inArray::Array{T}, inFunction::Function, inStartValue::FoldT)  where {T, FoldT}
  local outResult::FoldT = inStartValue
  local e::T
  for i in 1:arrayLength(inArray)
    e = arrayGet(inArray, i)
    outResult = inFunction(e, i, outResult)
  end
  outResult
end

""" Takes a list and a function operating on two elements of the array.
The function performs a reduction of the array to a single value using the
function. Example:
reduce([1, 2, 3], intAdd) => 6 """
function reduce(inArray::Array{T}, inFunction::Function)  where {T}
  local outResult::T
  local rest::List{T}
  outResult = arrayGet(inArray, 1)
  for i in 2:arrayLength(inArray)
    outResult = inFunction(outResult, arrayGet(inArray, i))
  end
  outResult
end

""" Like arrayUpdate, but with the index first so it can be used with List.map. """
function updateIndexFirst(inIndex::ModelicaInteger, inValue::T, inArray::Array{T})  where {T}
  arrayUpdate(inArray, inIndex, inValue)
end

""" Like arrayGet, but with the index first so it can used with List.map. """
function getIndexFirst(inIndex::ModelicaInteger, inArray::Array{T})  where {T}
  local outElement::T = arrayGet(inArray, inIndex)
  outElement
end

""" Replaces the element with the given index in the second array with the value
of the corresponding element in the first array. """
function updatewithArrayIndexFirst(inIndex::ModelicaInteger, inArraySrc::Array{T}, inArrayDest::Array{T})  where {T}
  arrayUpdate(inArrayDest, inIndex, inArraySrc[inIndex])
end

function updatewithListIndexFirst(inList::List{ModelicaInteger}, inStartIndex::ModelicaInteger, inArraySrc::Array{T}, inArrayDest::Array{T})  where {T}
  for i in inStartIndex:inStartIndex + listLength(inList)
    arrayUpdate(inArrayDest, i, inArraySrc[i])
  end
end

function updateElementListAppend(inIndex::ModelicaInteger, inValue::List{T}, inArray::Array{List{T}})  where {T}
  arrayUpdate(inArray, inIndex, listAppend(inArray[inIndex], inValue))
end

""" Takes
- an element,
- a position (1..n)
- an array and
- a fill value
The function replaces the value at the given position in the array, if the
given position is out of range, the fill value is used to padd the array up
to that element position and then insert the value at the position.

Example:
replaceAtWithFill('A', 5, {'a', 'b', 'c'}, 'dummy') => {'a', 'b', 'c', 'dummy', 'A'} """
function replaceAtWithFill(inPos::ModelicaInteger, inTypeReplace::T, inTypeFill::T, inArray::Array{T})  where {T}
  local outArray::Array{T}

  outArray = expandToSize(inPos, inArray, inTypeFill)
  arrayUpdate(outArray, inPos, inTypeReplace)
  outArray
end

""" Expands an array to the given size, or does nothing if the array is already
large enough. """
function expandToSize(inNewSize::ModelicaInteger, inArray::Array{T}, inFill::T)  where {T}
  local outArray::Array{T}
  if inNewSize <= arrayLength(inArray)
    outArray = inArray
  else
    outArray = arrayCreate(inNewSize, inFill)
    copy(inArray, outArray)
  end
  outArray
end

""" Increases the number of elements of an array with inN. Each new element is
assigned the value inFill. """
function expand(inN::ModelicaInteger, inArray::Array{T}, inFill::T)  where {T}
  local outArray::Array{T}
  local len::ModelicaInteger
  if inN < 1
    outArray = inArray
  else
    len = arrayLength(inArray)
    outArray = arrayCreateNoInit(len + inN, inFill)
    copy(inArray, outArray)
    setRange(len + 1, len + inN, outArray, inFill)
  end
  outArray
end

""" Resizes an array with the given factor if the array is smaller than the
requested size. """
function expandOnDemand(inNewSize::ModelicaInteger #= The number of elements that should fit in the array. =#, inArray::Array{T} #= The array to resize. =#, inExpansionFactor::ModelicaReal #= The factor to resize the array with. =#, inFillValue::T #= The value to fill the new part of the array. =#)  where {T}
  local outArray::Array{T} #= The resulting array. =#

  local new_size::ModelicaInteger
  local len::ModelicaInteger = arrayLength(inArray)

  if inNewSize <= len
    outArray = inArray
  else
    new_size = realInt(intReal(len) * inExpansionFactor)
    outArray = arrayCreateNoInit(new_size, inFillValue)
    copy(inArray, outArray)
    setRange(len + 1, new_size, outArray, inFillValue)
  end
  outArray #= The resulting array. =#
end

""" Concatenates an element to a list element of an array. """
function consToElement(inIndex::ModelicaInteger, inElement::T, inArray::Array{List{T}})  where {T}
  local outArray::Array{List{T}}
  outArray = arrayUpdate(inArray, inIndex, inElement <| inArray[inIndex])
  outArray
end

""" Appends a list to a list element of an array. """
function appendToElement(inIndex::ModelicaInteger, inElements::List{T}, inArray::Array{List{T}})  where {T}
  local outArray::Array{List{T}}
  outArray = arrayUpdate(inArray, inIndex, listAppend(inArray[inIndex], inElements))
  outArray
end

""" Returns a new array with the list elements added to the end of the given array. """
function appendList(arr::Array{T}, lst::List{T})  where {T}
  local outArray::Array{T}
  local arr_len::ModelicaInteger = arrayLength(arr)
  local lst_len::ModelicaInteger
  local e::T
  local rest::List{T}
  if listEmpty(lst)
    outArray = arr
  elseif arr_len == 0
    outArray = listArray(lst)
  else
    lst_len = listLength(lst)
    outArray = arrayCreateNoInit(arr_len + lst_len, arr[1])
    copy(arr, outArray)
    rest = lst
    for i in arr_len + 1:arr_len + lst_len
      @match e <| rest = rest
      arrayUpdateNoBoundsChecking(outArray, i, e)
    end
  end
  outArray
end

""" Copies all values from inArraySrc to inArrayDest. Fails if inArraySrc is
larger than inArrayDest.

NOTE: There's also a builtin arrayCopy operator that should be used if the
purpose is only to duplicate an array. """
function copy(inArraySrc::Array{T}, inArrayDest::Array{T})  where {T}
  local outArray::Array{T} = inArrayDest

  if arrayLength(inArraySrc) > arrayLength(inArrayDest)
    fail()
  end
  for i in 1:arrayLength(inArraySrc)
    arrayUpdateNoBoundsChecking(outArray, i, arrayGetNoBoundsChecking(inArraySrc, i))
  end
  outArray
end

""" Copies the first inN values from inArraySrc to inArrayDest. Fails if
inN is larger than either inArraySrc or inArrayDest. """
function copyN(inArraySrc::Array{T}, inArrayDest::Array{T}, inN::ModelicaInteger)  where {T}
  local outArray::Array{T} = inArrayDest
  if inN > arrayLength(inArrayDest) || inN > arrayLength(inArraySrc)
    fail()
  end
  for i in 1:inN
    arrayUpdateNoBoundsChecking(outArray, i, arrayGetNoBoundsChecking(inArraySrc, i))
  end
  outArray
end

""" Copies a range of elements from one array to another. """
function copyRange(srcArray::Array{T} #= The array to copy from. =#, dstArray::Array{T} #= The array to insert into. =#, srcFirst::ModelicaInteger #= The index of the first element to copy. =#, srcLast::ModelicaInteger #= The index of the last element to copy. =#, dstPos::ModelicaInteger #= The index to begin inserting at. =#)  where {T}
  local offset::ModelicaInteger = dstPos - srcFirst
  if srcFirst > srcLast || srcLast > arrayLength(srcArray) || offset + srcLast > arrayLength(dstArray)
    fail()
  end
  for i in srcFirst:srcLast
    arrayUpdateNoBoundsChecking(dstArray, offset + i, arrayGetNoBoundsChecking(srcArray, i))
  end
end

""" Creates an array<Integer> of size inLen with the values set to the range of 1:inLen. """
function createIntRange(inLen::ModelicaInteger) ::Array{ModelicaInteger}
  local outArray::Array{ModelicaInteger}
  outArray = arrayCreateNoInit(inLen, 0)
  for i in 1:inLen
    arrayUpdateNoBoundsChecking(outArray, i, i)
  end
  outArray
end

""" Sets the elements in positions inStart to inEnd to inValue. """
function setRange(inStart::ModelicaInteger, inEnd::ModelicaInteger, inArray::Array{T}, inValue::T)  where {T}
  local outArray::Array{T} = inArray
  if inStart > arrayLength(inArray)
    fail()
  end
  for i in inStart:inEnd
    arrayUpdate(inArray, i, inValue)
  end
  outArray
end

""" Gets the elements between inStart and inEnd. """
function getRange(inStart::ModelicaInteger, inEnd::ModelicaInteger, inArray::Array{T})  where {T}
  local outList::List{T} = nil()
  local value::T
  if inStart > arrayLength(inArray)
    fail()
  end
  for i in inStart:inEnd
    value = arrayGet(inArray, i)
    outList = value <| outList
  end
  outList
end

""" Returns the index of the given element in the array, or 0 if it wasn't found. """
function position(inArray::Array{T}, inElement::T, inFilledSize::ModelicaInteger = arrayLength(inArray) #= The filled size of the array. =#)  where {T}
  local outIndex::ModelicaInteger
  local e::T
  for i in 1:inFilledSize
    if valueEq(inElement, inArray[i])
      outIndex = i
      return outIndex
    end
  end
  outIndex = 0
  outIndex
end

""" Takes a value and returns the first element for which the comparison
function returns true, along with that elements position in the array. """
function getMemberOnTrue(inValue::VT, inArray::Array{ET}, inFunction::Function)  where {VT, ET}
  local outIndex::ModelicaInteger
  local outElement::ET
  for i in 1:arrayLength(inArray)
    if inFunction(inValue, arrayGetNoBoundsChecking(inArray, i))
      outElement = arrayGetNoBoundsChecking(inArray, i)
      outIndex = i
      return (outElement, outIndex)
    end
  end
  fail()
  (outElement, outIndex)
end

""" reverses the elements in an array """
function reverse(inArray::Array{T})  where {T}
  local outArray::Array{T}
  local size::ModelicaInteger
  local i::ModelicaInteger
  local elem1::T
  local elem2::T
  outArray = inArray
  size = arrayLength(inArray)
  for i in 1:size / 2
    elem1 = arrayGet(inArray, i)
    elem2 = arrayGet(inArray, size - i + 1)
    outArray = arrayUpdate(outArray, i, elem2)
    outArray = arrayUpdate(outArray, size - i + 1, elem1)
  end
  outArray
end

""" output true if all lists in the array are empty """
function arrayListsEmpty(arr::Array{List{T}})  where {T}
  local isEmpty::Bool
  isEmpty = fold(arr, arrayListsEmpty1, true)
  isEmpty
end

function arrayListsEmpty1(lst::List{T}, isEmptyIn::Bool)  where {T}
  local isEmptyOut::Bool
  isEmptyOut = listEmpty(lst) && isEmptyIn
  isEmptyOut
end

""" Checks if two arrays are equal. """
function isEqual(inArr1::Array{T}, inArr2::Array{T})  where {T}
  local outIsEqual::Bool = true
  local arrLength::ModelicaInteger
  arrLength = arrayLength(inArr1)
  if ! intEq(arrLength, arrayLength(inArr2))
    fail()
  end
  for i in 1:arrLength
    if ! valueEq(inArr1[i], inArr2[i])
      outIsEqual = false
      break
    end
  end
  outIsEqual
end

""" Returns true if a certain element exists in the given array as indicated by
the given predicate function. """
function exist(arr::Array{T}, pred::Function)  where {T}
  local exists::Bool
  for e in arr
    if pred(e)
      exists = true
      return exists
    end
  end
  exists = false
  exists
end

function insertList(arr::Array{T}, lst::List{T}, startPos::ModelicaInteger)  where {T}
  local i::ModelicaInteger = startPos
  for e in lst
    arr[i] = e
    i = i + 1
  end
  arr
end

#= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
@exportAll()
end
