module ListUtil

using MetaModelica
#= ExportAll is not good practice but it makes it so that we do not have to write export after each function :( =#
using ExportAll
  #= Necessary to write declarations for your uniontypes until Julia adds support for mutually recursive types =#
  CompFunc = Function

CompFunc = Function

Predicate = Function

CompareFunc = Function

CompareFunc = Function

CompareFunc = Function

CompareFunc = Function

CompareFunc = Function

CompareFunc = Function

CompareFunc = Function

CompareFunc = Function

CompareFunc = Function

CompFunc = Function

CompFunc = Function

PredicateFunc = Function

PredicateFunc = Function

PredicateFunc = Function

CompFunc = Function

MapFunc = Function

CompFunc = Function

CompFunc = Function

CompFunc = Function

CompFunc = Function

CompFunc = Function

CompFunc = Function

CompFunc = Function

CompFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc1 = Function
MapFunc2 = Function

MapFunc1 = Function
MapFunc2 = Function

ApplyFunc = Function
FoldFunc = Function

ApplyFunc = Function
FoldFunc = Function

MapFunc = Function

MapFunc = Function

MapBFunc = Function
MapFunc = Function
FoldFunc = Function

FuncType = Function

FoldFunc = Function

ReduceFunc = Function

ReduceFunc = Function

MapFunc = Function

FoldFunc = Function

FoldFunc = Function

FoldFunc = Function

FoldFunc = Function

FoldFunc = Function

FuncType = Function

PredFunc = Function

PredFunc = Function

CompFunc = Function

CompFunc = Function

FindFunc = Function

FilterFunc = Function

FilterFunc = Function

FilterFunc = Function
UpdateFunc = Function

FilterFunc = Function

FilterFunc = Function

CompFunc = Function

SelectFunc = Function

SelectFunc = Function

SelectFunc = Function

SelectFunc = Function

CompareFunc = Function

FuncType = Function

FuncType = Function

GenerateFunc = Function

GenerateFunc = Function

MapFunc = Function
FoldFunc = Function

MapFunc = Function
FoldFunc = Function

MapFunc = Function

MapFunc = Function

MapFunc = Function

FuncType = Function

EqFunc = Function

MapFunc = Function

CompFunc = Function

PredFunc = Function

FilterFunc = Function

FilterFunc = Function

FindMapFunc = Function

Comp = Function

MapFunc = Function

#= /*
* This file is part of OpenModelica.
*
* Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

import MetaModelica.ArrayUtil
using MetaModelica.Dangerous: listReverseInPlace, arrayGetNoBoundsChecking, arrayUpdateNoBoundsChecking, arrayCreateNoInit
import MetaModelica.Dangerous

#= Creates a list from an element. =#
function create(inElement::T)  where {T}
  local outList::List{T} = list(inElement)
  outList
end

#= Creates a list from two elements. =#
function create2(inElement1::T, inElement2::T)  where {T}
  local outList::List{T} = list(inElement1, inElement2)
  outList
end

#= Returns a list of n element.
Example: fill(2, 3) => {2, 2, 2} =#
function fill(inElement::T, inCount::ModelicaInteger)  where {T}
  local outList::List{T} = nil

  local i::ModelicaInteger = 0

  while i < inCount
    outList = inElement <| outList
    i = i + 1
  end
  outList
end

#= Returns a list of n integers from 1 to inStop.
Example: listIntRange(3) => {1,2,3} =#
function intRange(inStop::ModelicaInteger) ::List{ModelicaInteger}
  local outRange::List{ModelicaInteger} = nil

  local i::ModelicaInteger = inStop

  while i > 0
    outRange = i <| outRange
    i = i - 1
  end
  outRange
end

#= Returns a list of integers from inStart to inStop.
Example listIntRange2(3,5) => {3,4,5} =#
function intRange2(inStart::ModelicaInteger, inStop::ModelicaInteger) ::List{ModelicaInteger}
  local outRange::List{ModelicaInteger} = nil

  local i::ModelicaInteger = inStop

  if inStart < inStop
    while i >= inStart
      outRange = i <| outRange
      i = i - 1
    end
  else
    while i <= inStart
      outRange = i <| outRange
      i = i + 1
    end
  end
  outRange
end

#= Returns a list of integers from inStart to inStop with step inStep.
Example: listIntRange2(3,2,9) => {3,5,7,9} =#
function intRange3(inStart::ModelicaInteger, inStep::ModelicaInteger, inStop::ModelicaInteger) ::List{ModelicaInteger}
  local outRange::List{ModelicaInteger}

  if inStep == 0
    fail()
  end
  outRange = list(i for i in inStart:inStep:inStop)
  outRange
end

#= Returns an option of the element in a list if the list contains exactly one
element, NONE() if the list is empty and fails if the list contains more than
one element. =#
function toOption(inList::List{T})  where {T}
  local outOption::Option{T}

  outOption = begin
    local e::T
    @match inList begin
      nil()  => begin
        NONE()
      end

      e <|  nil()  => begin
        SOME(e)
      end
    end
  end
  outOption
end

#= Returns an empty list for NONE() and a list containing the element for
SOME(element). =#
function fromOption(inElement::Option{T})  where {T}
  local outList::List{T}

  outList = begin
    local e::T
    @match inElement begin
      SOME(e)  => begin
        list(e)
      end

      _  => begin
        nil
      end
    end
  end
  outList
end

#= Fails if the given list is not empty. =#
function assertIsEmpty(inList::List{T})  where {T}
  @match nil() = inList
end

#= Checks if two lists are equal. If inEqualLength is true the lists are assumed
to be of equal length, and if it is false they can be of different lengths (in
which case only the overlapping parts of the lists are checked). =#
function isEqual(inList1::List{T}, inList2::List{T}, inEqualLength::Bool)  where {T}
  local outIsEqual::Bool

  outIsEqual = begin
    local e1::T
    local e2::T
    local rest1::List{T}
    local rest2::List{T}
    @match (inList1, inList2, inEqualLength) begin
      (e1 <| rest1, e2 <| rest2, _) where (valueEq(e1, e2))  => begin
        isEqual(rest1, rest2, inEqualLength)
      end

      ( nil(),  nil(), _)  => begin
        true
      end

      ( nil(), _, false)  => begin
        true
      end

      (_,  nil(), false)  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outIsEqual
end

#= Takes two lists and an equality function, and returns whether the lists are
equal or not. =#
function isEqualOnTrue(inList1::List{T1}, inList2::List{T2}, inCompFunc::CompFunc)  where {T1, T2}
  local outIsEqual::Bool

  outIsEqual = begin
    local e1::T1
    local e2::T2
    local rest1::List{T1}
    local rest2::List{T2}
    @match (inList1, inList2) begin
      (e1 <| rest1, e2 <| rest2) where (inCompFunc(e1, e2))  => begin
        isEqualOnTrue(rest1, rest2, inCompFunc)
      end

      ( nil(),  nil())  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outIsEqual
end

#= Checks if the first list is a prefix of the second list, i.e. that all
elements in the first list is equal to the corresponding elements in the
second list. =#
function isPrefixOnTrue(inList1::List{T1}, inList2::List{T2}, inCompFunc::CompFunc)  where {T1, T2}
  local outIsPrefix::Bool

  outIsPrefix = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    @match (inList1, inList2) begin
      (e1 <| rest1, e2 <| rest2) where (inCompFunc(e1, e2))  => begin
        isPrefixOnTrue(rest1, rest2, inCompFunc)
      end

      ( nil(), _)  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outIsPrefix
end

#= The same as the builtin cons operator, but with the order of the arguments
swapped. =#
function consr(inList::List{T}, inElement::T)  where {T}
  local outList::List{T}

  outList = inElement <| inList
  outList
end

#= Adds the element to the front of the list if the condition is true. =#
function consOnTrue(inCondition::Bool, inElement::T, inList::List{T})  where {T}
  local outList::List{T}

  outList = if inCondition
    inElement <| inList
  else
    inList
  end
  outList
end

#= Adds the element to the front of the list if the predicate succeeds.
Prefer using consOnTrue instead of this function, it's more efficient. =#
function consOnSuccess(inElement::T, inList::List{T}, inPredicate::Predicate)  where {T}
  local outList::List{T}

  try
    inPredicate(inElement)
    outList = inElement <| inList
  catch
    outList = inList
  end
  outList
end

#= Adds an optional element to the front of the list, or returns the list if the
element is none. =#
function consOption(inElement::Option{T}, inList::List{T})  where {T}
  local outList::List{T}

  outList = begin
    local e::T
    @match inElement begin
      SOME(e)  => begin
        e <| inList
      end

      _  => begin
        inList
      end
    end
  end
  outList
end

#= Adds an element to one of two lists, depending on the given boolean value. =#
function consOnBool(inValue::Bool, inElement::T, trueList::List{T}, falseList::List{T})  where {T}



  if inValue
    trueList = inElement <| trueList
  else
    falseList = inElement <| falseList
  end
  (trueList, falseList)
end

#= concate n time inElement to the list:
n = 5, inElement=1, list={1,2} -> list={1,1,1,1,1,1,2} =#
function consN(size::ModelicaInteger, inElement::T, inList::List{T})  where {T}


  for i in 1:size
    inList = inElement <| inList
  end
  inList
end

#= Appends the elements from list1 in reverse order to list2. =#
function append_reverse(inList1::List{T}, inList2::List{T})  where {T}
  local outList::List{T} = inList2

  #=  Do not optimize the case listEmpty(inList2) and listLength(inList1)==1
  =#
  #=  since we use listReverseInPlace together with this function.
  =#
  #=  An alternative would be to keep both (and rename this append_reverse_always_copy)
  =#
  for e in inList1
    outList = e <| outList
  end
  outList
end

#= Appends the elements from list2 in reverse order to list1. =#
function append_reverser(inList1::List{T}, inList2::List{T})  where {T}
  local outList::List{T} = inList1

  #=  Do not optimize the case listEmpty(inList2) and listLength(inList1)==1
  =#
  #=  since we use listReverseInPlace together with this function.
  =#
  #=  An alternative would be to keep both (and rename this append_reverse_always_copy)
  =#
  for e in inList2
    outList = e <| outList
  end
  outList
end

#= Appends two lists in reverse order compared to listAppend. =#
function appendr(inList1::List{T}, inList2::List{T})  where {T}
  local outList::List{T}

  outList = listAppend(inList2, inList1)
  outList
end

#= Appends an element to the end of the list. Note that this is very
inefficient, so try to avoid using this function. =#
function appendElt(inElement::T, inList::List{T})  where {T}
  local outList::List{T}

  outList = listAppend(inList, list(inElement))
  outList
end

#= Appends a list to the last list in a list of lists. =#
function appendLastList(inListList::List{List{T}}, inList::List{T})  where {T}
  local outListList::List{List{T}}

  outListList = begin
    local l::List{T}
    local ll::List{List{T}}
    local ol::List{List{T}} = nil
    @match (inListList, inList) begin
      ( nil(), _)  => begin
        list(inList)
      end

      (l <|  nil(), _)  => begin
        list(listAppend(l, inList))
      end

      (l <| ll, _)  => begin
        while ! listEmpty(ll)
          ol = l <| ol
          @match l <| ll = ll
        end
        ol = listAppend(l, inList) <| ol
        ol = listReverseInPlace(ol)
        ol
      end
    end
  end
  outListList
end

#= Inserts an element at a position
example: insert({2,1,4,2},2,3) => {2,3,1,4,2}  =#
function insert(inList::List{T}, inN::ModelicaInteger, inElement::T)  where {T}
  local outList::List{T}

  local lst1::List{T}
  local lst2::List{T}

  @match true = inN > 0
  (lst1, lst2) = splitr(inList, inN - 1)
  outList = append_reverse(lst1, inElement <| lst2)
  outList
end

#= Inserts an sorted list into another sorted list. O(n)
example: insertListSorted({1,2,4,5},{3,4,8},intGt) => {1,2,3,4,4,5,8} =#
function insertListSorted(inList::List{T}, inList2::List{T}, inCompFunc::CompareFunc)  where {T}
  local outList::List{T}

  outList = listReverseInPlace(insertListSorted1(inList, inList2, inCompFunc, nil))
  outList
end

#= Iterate over the first given list and add it to the result list if the comparison function with the head of the second list returns true.
The result is a sorted list in reverse order. =#
function insertListSorted1(inList::List{T}, inList2::List{T}, inCompFunc::CompareFunc, inResultList::List{T})  where {T}
  local outResultList::List{T}

  local listRest::List{T}
  local listRest2::List{T}
  local tmpResultList::List{T}
  local listHead::T
  local listHead2::T
  local elem::T

  outResultList = begin
    @match (inList, inList2, inCompFunc, inResultList) begin
      ( nil(),  nil(), _, _)  => begin
        inResultList
      end

      ( nil(), _, _, _)  => begin
        append_reverse(inList2, inResultList)
      end

      (_,  nil(), _, _)  => begin
        append_reverse(inList, inResultList)
      end

      (listHead <| listRest, listHead2 <| listRest2, _, _)  => begin
        if inCompFunc(listHead, listHead2)
          tmpResultList = listHead <| inResultList
          tmpResultList = insertListSorted1(listRest, inList2, inCompFunc, tmpResultList)
        else
          tmpResultList = listHead2 <| inResultList
          tmpResultList = insertListSorted1(inList, listRest2, inCompFunc, tmpResultList)
        end
        tmpResultList
      end
    end
  end
  outResultList
end

#= set an element at a position
example: set({2,1,4,2},2,3) => {2,3,4,2}  =#
function set(inList::List{T}, inN::ModelicaInteger, inElement::T)  where {T}
  local outList::List{T}

  local lst1::List{T}
  local lst2::List{T}

  @match true = inN > 0
  (lst1, lst2) = splitr(inList, inN - 1)
  lst2 = stripFirst(lst2)
  outList = append_reverse(lst1, inElement <| lst2)
  outList
end

#= Returns the first element of a list. Fails if the list is empty. =#
function first(inList::List{T})  where {T}
  local out::T

  out = begin
    local e::T
    @match inList begin
      e <| _  => begin
        e
      end
    end
  end
  out
end

#= Returns the first element of a list as a list, or an empty list if the given
list is empty. =#
function firstOrEmpty(inList::List{T})  where {T}
  local outList::List{T}

  outList = begin
    local e::T
    @match inList begin
      e <| _  => begin
        list(e)
      end

      _  => begin
        nil
      end
    end
  end
  outList
end

#= Returns the second element of a list. Fails if the list is empty. =#
function second(inList::List{T})  where {T}
  local outSecond::T

  outSecond = listGet(inList, 2)
  outSecond
end

#= Returns the last element of a list. Fails if the list is empty. =#
function last(inList::List{T})  where {T}
  local outLast::T

  local rest::List{T}

  @match outLast <| rest = inList
  for e in rest
    outLast = e
  end
  outLast
end

#= Returns the last cons-cell of a list. Fails if the list is empty. Also returns the list length. =#
function lastElement(inList::List{T})  where {T}
  local listLength::ModelicaInteger = 0
  local lst::List{T}

  local rest::List{T} = inList

  @match false = listEmpty(rest)
  while ! listEmpty(rest)
    @match (@match _ <| rest = lst) = rest
    listLength = listLength + 1
  end
  (lst, listLength)
end

#= Returns the last element(list) of a list of lists. Returns empty list
if the outer list is empty. =#
function lastListOrEmpty(inListList::List{List{T}})  where {T}
  local outLastList::List{T} = nil

  for e in inListList
    outLastList = e
  end
  outLastList
end

#= Returns the second last element of a list, or fails if such an element does
not exist. =#
function secondLast(inList::List{T})  where {T}
  local outSecondLast::T

  @match _ <| outSecondLast <| _ = listReverse(inList)
  outSecondLast
end

#= Returns the last N elements of a list. =#
function lastN(inList::List{T}, inN::ModelicaInteger)  where {T}
  local outList::List{T}

  local len::ModelicaInteger

  @match true = inN >= 0
  len = listLength(inList)
  outList = stripN(inList, len - inN)
  outList
end

#= Returns all elements except for the first in a list. =#
function rest(inList::List{T})  where {T}
  local outList::List{T}

  @match _ <| outList = inList
  outList
end

#= Returns all elements except for the first in a list. =#
function restCond(cond::Bool, inList::List{T})  where {T}
  local outList::List{T}

  outList = if cond
    listRest(inList)
  else
    inList
  end
  outList
end

#= Returns all elements except for the first in a list, or the empty list of the
list is empty. =#
function restOrEmpty(inList::List{T})  where {T}
  local outList::List{T}

  outList = if listEmpty(inList)
    inList
  else
    listRest(inList)
  end
  outList
end

function getIndexFirst(index::ModelicaInteger, inList::List{T})  where {T}
  local element::T

  element = listGet(inList, index)
  element
end

#= Returns the first N elements of a list, or fails if there are not enough
elements in the list. =#
function firstN(inList::List{T}, inN::ModelicaInteger)  where {T}
  local outList::List{T} = nil

  local e::T
  local rest::List{T}

  @match true = inN >= 0
  rest = inList
  for i in 1:inN
    @match e <| rest = rest
    outList = e <| outList
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Removes the first element of a list, but returns the empty list if the given
list is empty. =#
function stripFirst(inList::List{T})  where {T}
  local outList::List{T}

  if listEmpty(inList)
    outList = nil
  else
    @match _ <| outList = inList
  end
  outList
end

#= Removes the last element of a list. If the list is the empty list, the
function returns the empty list. =#
function stripLast(inList::List{T})  where {T}
  local outList::List{T}

  if listEmpty(inList)
    outList = nil
  else
    @match _ <| outList = listReverse(inList)
    outList = listReverseInPlace(outList)
  end
  outList
end

#= Strips the N first elements from a list. Fails if the list contains less than
N elements, or if N is negative. =#
function stripN(inList::List{T}, inN::ModelicaInteger)  where {T}
  local outList::List{T} = inList

  @match true = inN >= 0
  for i in 1:inN
    @match _ <| outList = outList
  end
  outList
end

function heapSortIntList(lst::List{<:ModelicaInteger}) ::List{ModelicaInteger}


  lst = begin
    @match lst begin
      nil()  => begin
        lst
      end

      _ <|  nil()  => begin
        lst
      end

      _  => begin
        arrayList(ArrayUtil.heapSort(listArray(lst)))
      end
    end
  end
  lst
end

#= Sorts a list given an ordering function with the mergesort algorithm.
Example:
sort({2, 1, 3}, intGt) => {1, 2, 3}
sort({2, 1, 3}, intLt) => {3, 2, 1} =#
function sort(inList::List{T}, inCompFunc::CompareFunc)  where {T}
  local outList::List{T} = nil

  local rest::List{T} = inList
  local e1::T
  local e2::T
  local left::List{T}
  local right::List{T}
  local middle::ModelicaInteger

  if ! listEmpty(rest)
    @match e1 <| rest = rest
    if listEmpty(rest)
      outList = inList
    else
      @match e2 <| rest = rest
      if listEmpty(rest)
        outList = if inCompFunc(e2, e1)
          inList
        else
          list(e2, e1)
        end
      else
        middle = intDiv(listLength(inList), 2)
        (left, right) = split(inList, middle)
        left = sort(left, inCompFunc)
        right = sort(right, inCompFunc)
        outList = merge(left, right, inCompFunc, nil)
      end
    end
  end
  outList
end

#= Returns a list of all duplicates in a sorted list, using the given comparison
function to check for equality. =#
function sortedDuplicates(inList::List{T}, inCompFunc::CompareFunc #= Equality comparator =#)  where {T}
  local outDuplicates::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest)
    @match e <| rest = rest
    if ! listEmpty(rest) && inCompFunc(e, listHead(rest))
      outDuplicates = e <| outDuplicates
    end
  end
  outDuplicates = listReverseInPlace(outDuplicates)
  outDuplicates
end

#= The input is a sorted list. The functions checks if all elements are unique. =#
function sortedListAllUnique(lst::List{T}, compare::CompareFunc)  where {T}
  local allUnique::Bool = false

  local e::T
  local rest::List{T} = lst

  while ! listEmpty(rest)
    rest = begin
      local e1::T
      local e2::T
      @match rest begin
        _ <|  nil()  => begin
          nil
        end

        e1 <| rest && e2 <| _  => begin
          if compare(e1, e2)
            return
          end
          rest
        end
      end
    end
  end
  allUnique = true
  allUnique
end

#= Returns a list of unique elements in a sorted list, using the given
comparison function to check for equality. =#
function sortedUnique(inList::List{T}, inCompFunc::CompareFunc)  where {T}
  local outUniqueElements::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest)
    @match e <| rest = rest
    if listEmpty(rest) || ! inCompFunc(e, listHead(rest))
      outUniqueElements = e <| outUniqueElements
    end
  end
  outUniqueElements = listReverseInPlace(outUniqueElements)
  outUniqueElements
end

#= Returns a list with all duplicate elements removed, as well as a list of the
removed elements, using the given comparison function to check for equality. =#
function sortedUniqueAndDuplicates(inList::List{T}, inCompFunc::CompareFunc)  where {T}
  local outDuplicateElements::List{T} = nil
  local outUniqueElements::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest)
    @match e <| rest = rest
    if ! listEmpty(rest) && inCompFunc(e, listHead(rest))
      outDuplicateElements = e <| outDuplicateElements
    else
      outUniqueElements = e <| outUniqueElements
    end
  end
  outUniqueElements = listReverseInPlace(outUniqueElements)
  outDuplicateElements = listReverseInPlace(outDuplicateElements)
  (outUniqueElements, outDuplicateElements)
end

#= Returns a list with all duplicate elements removed, as well as a list of the
removed elements, using the given comparison function to check for equality. =#
function sortedUniqueOnlyDuplicates(inList::List{T}, inCompFunc::CompareFunc)  where {T}
  local outDuplicateElements::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest)
    @match e <| rest = rest
    if ! listEmpty(rest) && inCompFunc(e, listHead(rest))
      outDuplicateElements = e <| outDuplicateElements
    end
  end
  outDuplicateElements = listReverseInPlace(outDuplicateElements)
  outDuplicateElements
end

#= Helper function to sort, merges two sorted lists. =#
function merge(inLeft::List{T}, inRight::List{T}, inCompFunc::CompareFunc, acc::List{T})  where {T}
  local outList::List{T}

  outList = begin
    local b::Bool
    local l::T
    local r::T
    local el::T
    local l_rest::List{T}
    local r_rest::List{T}
    local res::List{T}
    #= /* Tail recursive version */ =#
    @match (inLeft, inRight) begin
      (l <| l_rest, r <| r_rest)  => begin
        if inCompFunc(r, l)
          r_rest = inRight
          el = l
        else
          l_rest = inLeft
          el = r
        end
        merge(l_rest, r_rest, inCompFunc, el <| acc)
      end

      ( nil(),  nil())  => begin
        listReverseInPlace(acc)
      end

      ( nil(), _)  => begin
        append_reverse(acc, inRight)
      end

      (_,  nil())  => begin
        append_reverse(acc, inLeft)
      end
    end
  end
  outList
end

#= This function merges two sorted lists into one sorted list. It takes a
comparison function that defines a strict weak ordering of the elements, i.e.
that returns true if the first element should be placed before the second
element in the sorted list. =#
function mergeSorted(inList1::List{T}, inList2::List{T}, inCompFunc::CompFunc)  where {T}
  local outList::List{T} = nil

  local l1::List{T}
  local l2::List{T}
  local e1::T
  local e2::T

  l1 = inList1
  l2 = inList2
  #=  While both lists contain elements.
  =#
  while ! listEmpty(l1) && ! listEmpty(l2)
    @match e1 <| _ = l1
    @match e2 <| _ = l2
    if inCompFunc(e1, e2)
      outList = e1 <| outList
      @match _ <| l1 = l1
    else
      outList = e2 <| outList
      @match _ <| l2 = l2
    end
  end
  #=  Move the smallest head from either list to accumulator.
  =#
  #=  Reverse accumulator and append the remaining elements.
  =#
  l1 = if listEmpty(l1)
    l2
  else
    l1
  end
  outList = append_reverse(outList, l1)
  outList
end

#= Provides same functionality as sort, but for integer values between 1
and N. The complexity in this case is O(n) =#
function sortIntN(inList::List{<:ModelicaInteger}, inN::ModelicaInteger) ::List{ModelicaInteger}
  local outSorted::List{ModelicaInteger} = nil
  local a1::Array{Bool}
  a1 = arrayCreate(inN, false)
  a1 = fold1r(inList, arrayUpdate, true, a1)
  for i in inN:(-1):1
    if a1[i]
      outSorted = i <| outSorted
    end
  end
  outSorted
end

#= Takes a list of elements and returns a list with duplicates removed, so that
each element in the new list is unique. =#
function unique(inList::List{T})  where {T}
  local outList::List{T} = nil

  for e in inList
    if ! listMember(e, outList)
      outList = e <| outList
    end
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Takes a list of integes and returns a list with duplicates removed, so that
each element in the new list is unique. O(listLength(inList)) =#
function uniqueIntN(inList::List{<:ModelicaInteger}, inN::ModelicaInteger) ::List{ModelicaInteger}
  local outList::List{ModelicaInteger} = nil

  local arr::Array{Bool}

  arr = arrayCreate(inN, true)
  for i in inList
    if arrayGet(arr, i)
      outList = i <| outList
    end
    arrayUpdate(arr, i, false)
  end
  outList
end

#= Takes a list of integes and returns a list with duplicates removed, so that
each element in the new list is unique. O(listLength(inList)). The function
also takes an array of Integer of size N+1 to mark the already selected entries <= N.
The last entrie of the array is used for the mark index. It will be updated after
each call =#
function uniqueIntNArr(inList::List{<:ModelicaInteger}, inMarkArray::Array{<:ModelicaInteger}, inAccum::List{<:ModelicaInteger}) ::List{ModelicaInteger}
  local outAccum::List{ModelicaInteger}

  local len::ModelicaInteger
  local mark::ModelicaInteger

  if listEmpty(inList)
    outAccum = inAccum
  else
    len = arrayLength(inMarkArray)
    mark = inMarkArray[len]
    arrayUpdate(inMarkArray, len, mark + 1)
    outAccum = uniqueIntNArr1(inList, len, mark + 1, inMarkArray, inAccum)
  end
  outAccum
end

#= Helper for uniqueIntNArr1. =#
function uniqueIntNArr1(inList::List{<:ModelicaInteger}, inLength::ModelicaInteger, inMark::ModelicaInteger, inMarkArray::Array{<:ModelicaInteger}, inAccum::List{<:ModelicaInteger}) ::List{ModelicaInteger}
  local outAccum::List{ModelicaInteger} = inAccum

  for i in inList
    if i >= inLength
      fail()
    end
    if arrayGet(inMarkArray, i) != inMark
      outAccum = i <| outAccum
      _ = arrayUpdate(inMarkArray, i, inMark)
    end
  end
  outAccum
end

#= Takes a list of elements and a comparison function over two elements of the
list and returns a list with duplicates removed, so that each element in the
new list is unique. =#
function uniqueOnTrue(inList::List{T}, inCompFunc::CompFunc)  where {T}
  local outList::List{T} = nil

  for e in inList
    if ! isMemberOnTrue(e, outList, inCompFunc)
      outList = e <| outList
    end
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Takes a list of lists and reverses it at both levels, i.e. both the list
itself and each sublist.
Example:
reverseList({{1, 2}, {3, 4, 5}, {6}}) => {{6}, {5, 4, 3}, {2, 1}} =#
function reverseList(inList::List{List{T}})  where {T}
  local outList::List{List{T}}

  outList = listReverse(listReverse(e) for e in inList)
  outList
end

#= Takes a list and a position, and splits the list at the position given.
Example: split({1, 2, 5, 7}, 2) => ({1, 2}, {5, 7}) =#
function split(inList::List{T}, inPosition::ModelicaInteger)  where {T}
  local outList2::List{T}
  local outList1::List{T}

  local pos::ModelicaInteger
  local l1::List{T} = nil
  local l2::List{T} = inList
  local e::T

  @match true = inPosition >= 0
  pos = inPosition
  #=  Move elements from l2 to l1 until we reach the split position.
  =#
  for i in 1:pos
    @match e <| l2 = l2
    l1 = e <| l1
  end
  outList1 = listReverseInPlace(l1)
  outList2 = l2
  (outList1, outList2)
end

#= Takes a list and a position, and splits the list at the position given. The first list is returned in reverse order.
Example: split({1, 2, 5, 7}, 2) => ({2, 1}, {5, 7}) =#
function splitr(inList::List{T}, inPosition::ModelicaInteger)  where {T}
  local outList2::List{T}
  local outList1::List{T}

  local pos::ModelicaInteger
  local l1::List{T} = nil
  local l2::List{T} = inList
  local e::T

  @match true = inPosition >= 0
  pos = inPosition
  #=  Move elements from l2 to l1 until we reach the split position.
  =#
  for i in 1:pos
    @match e <| l2 = l2
    l1 = e <| l1
  end
  outList1 = l1
  outList2 = l2
  (outList1, outList2)
end

#= Splits a list into two sublists depending on predicate function. =#
function splitOnTrue(inList::List{T}, inFunc::PredicateFunc)  where {T}
  local outFalseList::List{T} = nil
  local outTrueList::List{T} = nil

  for e in inList
    if inFunc(e)
      outTrueList = e <| outTrueList
    else
      outFalseList = e <| outFalseList
    end
  end
  outTrueList = listReverseInPlace(outTrueList)
  outFalseList = listReverseInPlace(outFalseList)
  (outTrueList, outFalseList)
end

#= Splits a list into two sublists depending on predicate function. =#
function split1OnTrue(inList::List{T}, inFunc::PredicateFunc, inArg1::ArgT1)  where {T, ArgT1}
  local outFalseList::List{T} = nil
  local outTrueList::List{T} = nil

  for e in inList
    if inFunc(e, inArg1)
      outTrueList = e <| outTrueList
    else
      outFalseList = e <| outFalseList
    end
  end
  outTrueList = listReverseInPlace(outTrueList)
  outFalseList = listReverseInPlace(outFalseList)
  (outTrueList, outFalseList)
end

#= Splits a list into two sublists depending on predicate function. =#
function split2OnTrue(inList::List{T}, inFunc::PredicateFunc, inArg1::ArgT1, inArg2::ArgT2)  where {T, ArgT1, ArgT2}
  local outFalseList::List{T} = nil
  local outTrueList::List{T} = nil

  for e in inList
    if inFunc(e, inArg1, inArg2)
      outTrueList = e <| outTrueList
    else
      outFalseList = e <| outFalseList
    end
  end
  outTrueList = listReverseInPlace(outTrueList)
  outFalseList = listReverseInPlace(outFalseList)
  (outTrueList, outFalseList)
end

#= Splits a list when the given function first finds a matching element.
Example: splitOnFirstMatch({1, 2, 3, 4, 5}, isThree) => ({1, 2}, {3, 4, 5}) =#
function splitOnFirstMatch(inList::List{T}, inFunc::CompFunc)  where {T}
  local outList2::List{T} = inList
  local outList1::List{T} = nil

  local e::T

  #=  Shuffle elements from outList2 to outList1 until we find a match.
  =#
  while ! listEmpty(outList2)
    @match e <| outList2 = outList2
    if inFunc(e)
      outList2 = e <| outList2
      break
    end
    outList1 = e <| outList1
  end
  outList1 = listReverseInPlace(outList1)
  (outList1, outList2)
end

#= Returns the first element of a list and the rest of the list. Fails if the
list is empty. =#
function splitFirst(inList::List{T})  where {T}
  local outRest::List{T}
  local outFirst::T

  @match outFirst <| outRest = inList
  (outFirst, outRest)
end

#= Returns the first element of a list as an option, and the rest of the list.
Returns NONE and {} if the list is empty. =#
function splitFirstOption(inList::List{T})  where {T}
  local outRest::List{T}
  local outFirst::Option{T}

  (outFirst, outRest) = begin
    local el::T
    local rest::List{T}
    @match inList begin
      el <| rest  => begin
        (SOME(el), rest)
      end

      _  => begin
        (NONE(), nil())
      end
    end
  end
  (outFirst, outRest)
end

#= Returns the last element of a list and a list of all previous elements. If
the list is the empty list, the function fails.
Example: splitLast({3, 5, 7, 11, 13}) => (13, {3, 5, 7, 11}) =#
function splitLast(inList::List{T})  where {T}
  local outRest::List{T}
  local outLast::T

  @match outLast <| outRest = listReverse(inList)
  outRest = listReverseInPlace(outRest)
  (outLast, outRest)
end

#= Splits a list into n equally sized parts.
Example: splitEqualParts({1, 2, 3, 4, 5, 6, 7, 8}, 4) =>
{{1, 2}, {3, 4}, {5, 6}, {7, 8}} =#
function splitEqualParts(inList::List{T}, inParts::ModelicaInteger)  where {T}
  local outParts::List{List{T}}

  local length::ModelicaInteger

  if inParts == 0
    outParts = nil
  else
    length = listLength(inList)
    @match 0 = intMod(length, inParts)
    outParts = partition(inList, intDiv(length, inParts))
  end
  outParts
end

#= Splits a list into two sublists depending on a second list of bools. =#
function splitOnBoolList(inList::List{T}, inBools::List{Bool})  where {T}
  local outFalseList::List{T} = nil
  local outTrueList::List{T} = nil

  local e::T
  local rest_e::List{T} = inList
  local b::Bool
  local rest_b::List{Bool} = inBools

  while ! listEmpty(rest_e)
    @match e <| rest_e = rest_e
    @match b <| rest_b = rest_b
    if b
      outTrueList = e <| outTrueList
    elseif isPresent(outFalseList)
      outFalseList = e <| outFalseList
    end
  end
  outTrueList = listReverseInPlace(outTrueList)
  outFalseList = listReverseInPlace(outFalseList)
  (outTrueList, outFalseList)
end

#= Partitions a list of elements into sublists of length n.
Example: partition({1, 2, 3, 4, 5}, 2) => {{1, 2}, {3, 4}, {5}} =#
function partition(inList::List{T}, inPartitionLength::ModelicaInteger)  where {T}
  local outPartitions::List{List{T}} = nil

  local lst::List{T} = inList
  local part::List{T}
  local length::ModelicaInteger

  @match true = inPartitionLength > 0
  length = listLength(inList)
  if length == 0
    return outPartitions
  elseif inPartitionLength >= length
    outPartitions = list(inList)
    return outPartitions
  end
  #=  Split the list into partitions.
  =#
  for i in 1:div(length, inPartitionLength)
    (part, lst) = split(lst, inPartitionLength)
    outPartitions = part <| outPartitions
  end
  #=  Append the remainder of the list.
  =#
  if ! listEmpty(lst)
    outPartitions = lst <| outPartitions
  end
  outPartitions = listReverseInPlace(outPartitions)
  outPartitions
end

#= Partitions a list of elements into even sublists of maximum length n.
Example: partition({1, 2, 3, 4, 5}, 2) => {{1, 2}, {3, 4}, {5}}
The number of partitions is the same as partition(), but chosen to be
as balanced in length as possible.
=#
function balancedPartition(lst::List{T}, maxLength::ModelicaInteger)  where {T}
  local outPartitions::List{List{T}}

  local length::ModelicaInteger
  local n::ModelicaInteger

  @match true = maxLength > 0
  if listEmpty(lst)
    outPartitions = nil
    return outPartitions
  end
  length = listLength(lst)
  n = intDiv(length - 1, maxLength) + 1
  outPartitions = partition(lst, intDiv(length - 1, n) + 1)
  outPartitions
end

#= Returns a sublist determined by an offset and length.
Example: sublist({1,2,3,4,5}, 2, 3) => {2,3,4} =#
function sublist(inList::List{T}, inOffset::ModelicaInteger, inLength::ModelicaInteger)  where {T}
  local outList::List{T} = nil

  local e::T
  local rest::List{T} = inList
  local res::List{T}

  @match true = inOffset > 0
  @match true = inLength >= 0
  #=  Remove elements until we reach the offset position.
  =#
  for i in 2:inOffset
    @match _ <| rest = rest
  end
  #=  Accumulate the given number of elements.
  =#
  for i in 1:inLength
    @match e <| rest = rest
    outList = e <| outList
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Given two lists and a function, forms the cartesian product of the lists and
applies the function to each resulting pair.
Example: productMap({1, 2}, {3, 4}, intMul) = {1*3, 1*4, 2*3, 2*4} =#
function productMap(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc)  where {T1, T2}
  local outResult::List = nil

  for e1 in listReverse(inList1), e2 in listReverse(inList2)
    outResult = inMapFunc(e1, e2) <| outResult
  end
  outResult
end

#= Given 2 lists, generate the product of them.
Example:
list1 = {{1}, {2}}, list2 = {{1}, {3}, {4}}
result = {{1, 1}, {1, 3}, {1, 4}, {2, 1}, {2, 3}, {2, 4}} =#
function product(inList1::List{List{T}}, inList2::List{List{T}})  where {T}
  local outProduct::List{List{T}} = nil

  for e1 in inList1, e2 in inList2
    outProduct = listAppend(e1, e2) <| outProduct
  end
  outProduct
end

#= Transposes a list of lists. Example:
transposeList({{1, 2, 3}, {4, 5, 6}}) => {{1, 4}, {2, 5}, {3, 6}} =#
function transposeList(inList::List{List{T}})  where {T}
  local outList::List{List{T}} = nil

  local arr::Array{Array{T}}
  local arr_row::Array{T}
  local new_row::List{T}
  local c_len::ModelicaInteger
  local r_len::ModelicaInteger

  if listEmpty(inList)
    return outList
  end
  #=  Convert the list into an array, it's a lot more efficient than fiddling
  =#
  #=  around with lists.
  =#
  arr = listArray(list(listArray(lst) for lst in inList))
  #=  Get the dimensions of the array.
  =#
  c_len = arrayLength(arr)
  r_len = arrayLength(arrayGet(arr, 1))
  #=  Loop through the array in reverse order so we can create the new lists
  =#
  #=  in the correct order without having to reverse them.
  =#
  for i in r_len:(-1):1
    new_row = nil
    for j in c_len:(-1):1
      new_row = arrayGetNoBoundsChecking(arrayGet(arr, j), i) <| new_row
    end
    outList = new_row <| outList
  end
  outList
end

function listArrayReverse(inLst::List{T})  where {T}
  local outArr::Array{T}

  local len::ModelicaInteger
  local defaultValue::T

  if listEmpty(inLst)
    outArr = listArray(inLst)
    return outArr
  end
  len = listLength(inLst)
  @match defaultValue <| _ = inLst
  outArr = arrayCreateNoInit(len, defaultValue)
  for e in inLst
    arrayUpdateNoBoundsChecking(outArr, len, e)
    len = len - 1
  end
  outArr
end

#= Takes two lists and a comparison function over two elements of the lists.
It returns true if the two sets are equal, false otherwise. =#
function setEqualOnTrue(inList1::List{T}, inList2::List{T}, inCompFunc::CompFunc)  where {T}
  local outIsEqual::Bool

  local lst::List{T}
  local lst_size::ModelicaInteger

  lst = intersectionOnTrue(inList1, inList2, inCompFunc)
  lst_size = listLength(lst)
  outIsEqual = intEq(lst_size, listLength(inList1)) && intEq(lst_size, listLength(inList2))
  outIsEqual
end

#= Provides same functionality as listIntersection, but for integer values
in sorted lists. The complexity in this case is O(n). =#
function intersectionIntSorted(inList1::List{<:ModelicaInteger}, inList2::List{<:ModelicaInteger}) ::List{ModelicaInteger}
  local outResult::List{ModelicaInteger} = nil

  local i1::ModelicaInteger
  local i2::ModelicaInteger
  local o1::ModelicaInteger
  local o2::ModelicaInteger
  local l1::List{ModelicaInteger} = inList1
  local l2::List{ModelicaInteger} = inList2

  if listEmpty(inList1) || listEmpty(inList2)
    return outResult
  end
  @match i1 <| l1 = l1
  @match i2 <| l2 = l2
  o1 = i1
  o2 = i2
  while true
    if i1 > i2
      if listEmpty(l2)
        break
      end
      @match i2 <| l2 = l2
      if o2 > i2
        fail()
      end
      o2 = i2
    elseif i1 < i2
      if listEmpty(l1)
        break
      end
      @match i1 <| l1 = l1
      if o1 > i1
        fail()
      end
      o1 = i1
    else
      outResult = i1 <| outResult
      if listEmpty(l1) || listEmpty(l2)
        break
      end
      @match i1 <| l1 = l1
      @match i2 <| l2 = l2
      if o1 > i1
        fail()
      end
      o1 = i1
      if o2 > i2
        fail()
      end
      o2 = i2
    end
  end
  outResult = listReverseInPlace(outResult)
  outResult
end

#= Provides same functionality as listIntersection, but for integer values
between 1 and N. The complexity in this case is O(n). =#
function intersectionIntN(inList1::List{<:ModelicaInteger}, inList2::List{<:ModelicaInteger}, inN::ModelicaInteger) ::List{ModelicaInteger}
  local outResult::List{ModelicaInteger}

  local a::Array{ModelicaInteger}

  if inN > 0
    a = arrayCreate(inN, 0)
    a = addPos(inList1, a, 1)
    a = addPos(inList2, a, 1)
    outResult = intersectionIntVec(a, inList1)
  else
    outResult = nil
  end
  outResult
end

#= Helper function to intersectionIntN. =#
function intersectionIntVec(inArray::Array{<:ModelicaInteger}, inList1::List{<:ModelicaInteger}) ::List{ModelicaInteger}
  local outResult::List{ModelicaInteger} = nil

  for i in inList1
    if arrayGet(inArray, i) == 2
      outResult = i <| outResult
    end
  end
  outResult
end

#= Helper function to intersectionIntN. =#
function addPos(inList::List{<:ModelicaInteger}, inArray::Array{<:ModelicaInteger}, inIndex::ModelicaInteger) ::Array{ModelicaInteger}
  local outArray::Array{ModelicaInteger}

  for i in inList
    _ = arrayUpdate(inArray, i, intAdd(arrayGet(inArray, i), inIndex))
  end
  outArray = inArray
  outArray
end

#= Takes two lists and a comparison function over two elements of the lists. It
returns the intersection of the two lists, using the comparison function
passed as argument to determine identity between two elements.
Example:
intersectionOnTrue({1, 4, 2}, {5, 2, 4, 6}, intEq) => {4, 2} =#
function intersectionOnTrue(inList1::List{T}, inList2::List{T}, inCompFunc::CompFunc)  where {T}
  local outIntersection::List{T} = nil

  for e in inList1
    if isMemberOnTrue(e, inList2, inCompFunc)
      outIntersection = e <| outIntersection
    end
  end
  outIntersection = listReverseInPlace(outIntersection)
  outIntersection
end

#= Takes two lists and a comparison function over two elements of the lists. It
returns the intersection of the two lists, using the comparison function
passed as argument to determine identity between two elements. This function
also returns a list of the elements from list 1 which is not in list 2 and a
list of the elements from list 2 which is not in list 1. =#
function intersection1OnTrue(inList1::List{T}, inList2::List{T}, inCompFunc::CompFunc)  where {T}
  local outList2Rest::List{T} = inList2
  local outList1Rest::List{T} = nil
  local outIntersection::List{T} = nil

  local oe::Option{T}

  if listEmpty(inList1)
    return (outIntersection, outList1Rest, outList2Rest)
  end
  if listEmpty(inList2)
    outList1Rest = inList1
    return (outIntersection, outList1Rest, outList2Rest)
  end
  for e in inList1
    if isMemberOnTrue(e, inList2, inCompFunc)
      outIntersection = e <| outIntersection
    elseif isPresent(outList1Rest)
      outList1Rest = e <| outList1Rest
    end
  end
  outIntersection = listReverseInPlace(outIntersection)
  outList1Rest = if isPresent(outList1Rest)
    listReverseInPlace(outList1Rest)
  else
    nil
  end
  outList2Rest = if isPresent(outList2Rest)
    setDifferenceOnTrue(inList2, outIntersection, inCompFunc)
  else
    nil
  end
  (outIntersection, outList1Rest, outList2Rest)
end

#= Provides same functionality as setDifference, but for integer values
between 1 and N. The complexity in this case is O(n) =#
function setDifferenceIntN(inList1::List{<:ModelicaInteger}, inList2::List{<:ModelicaInteger}, inN::ModelicaInteger) ::List{ModelicaInteger}
  local outDifference::List{ModelicaInteger} = nil

  local a::Array{ModelicaInteger}

  if inN > 0
    a = arrayCreate(inN, 0)
    a = addPos(inList1, a, 1)
    a = addPos(inList2, a, 1)
    for i in inN:(-1):1
      if arrayGet(a, i) == 1
        outDifference = i <| outDifference
      end
    end
  end
  outDifference
end

#= Takes two lists and a comparison function over two elements of the lists. It
returns the set difference of the two lists A-B, using the comparison
function passed as argument to determine identity between two elements.
Example:
setDifferenceOnTrue({1, 2, 3}, {1, 3}, intEq) => {2} =#
function setDifferenceOnTrue(inList1::List{T}, inList2::List{T}, inCompFunc::CompFunc)  where {T}
  local outDifference::List{T} = inList1

  #=  Empty - B = Empty
  =#
  if listEmpty(inList1)
    return outDifference
  end
  for e in inList2
    (outDifference, _) = deleteMemberOnTrue(e, outDifference, inCompFunc)
  end
  outDifference
end

#= Takes two lists and returns the set difference of two lists A - B.
Example:
setDifference({1, 2, 3}, {1, 3}) => {2} =#
function setDifference(inList1::List{T}, inList2::List{T})  where {T}
  local outDifference::List{T} = inList1

  if listEmpty(inList1)
    return outDifference
  end
  for e in inList2
    outDifference = deleteMember(outDifference, e)
  end
  outDifference
end

#= Provides same functionality as listUnion, but for integer values between 1
and N. The complexity in this case is O(n) =#
function unionIntN(inList1::List{<:ModelicaInteger}, inList2::List{<:ModelicaInteger}, inN::ModelicaInteger) ::List{ModelicaInteger}
  local outUnion::List{ModelicaInteger} = nil

  local a::Array{ModelicaInteger}

  if inN > 0
    a = arrayCreate(inN, 0)
    a = addPos(inList1, a, 1)
    a = addPos(inList2, a, 1)
    for i in inN:(-1):1
      if arrayGet(a, i) > 0
        outUnion = i <| outUnion
      end
    end
  end
  outUnion
end

#= Takes a value and a list of values and inserts the value into the list if it
is not already in the list. If it is in the list it is not inserted.
Example:
unionElt(1, {2, 3}) => {1, 2, 3}
unionElt(0, {0, 1, 2}) => {0, 1, 2} =#
function unionElt(inElement::T, inList::List{T})  where {T}
  local outList::List{T}

  outList = consOnTrue(! listMember(inElement, inList), inElement, inList)
  outList
end

#= Works as unionElt, but with a compare function. =#
function unionEltOnTrue(inElement::T, inList::List{T}, inCompFunc::CompFunc)  where {T}
  local outList::List{T}

  outList = consOnTrue(! isMemberOnTrue(inElement, inList, inCompFunc), inElement, inList)
  outList
end

#= Takes two lists and returns the union of the two lists, i.e. a list of all
elements combined without duplicates. Example:
union({0, 1}, {2, 1}) => {0, 1, 2} =#
function union(inList1::List{T}, inList2::List{T})  where {T}
  local outUnion::List{T} = nil

  for e in inList1
    outUnion = unionElt(e, outUnion)
  end
  for e in inList2
    outUnion = unionElt(e, outUnion)
  end
  outUnion = listReverseInPlace(outUnion)
  outUnion
end

#= As union but this function assume that List1 is already union.
i.e. a list of all elements combined without duplicates.
Example:
union({0, 1}, {2, 1}) => {0, 1, 2} =#
function unionAppendonUnion(inList1::List{T}, inList2::List{T})  where {T}
  local outUnion::List{T}

  outUnion = listReverse(inList1)
  for e in inList2
    outUnion = unionElt(e, outUnion)
  end
  outUnion = listReverseInPlace(outUnion)
  outUnion
end

#= Takes two lists an a comparison function over two elements of the lists. It
returns the union of the two lists, using the comparison function passed as
argument to determine identity between two elements. Example:
unionOnTrue({1, 2}, {2, 3}, intEq) => {1, 2, 3} =#
function unionOnTrue(inList1::List{T}, inList2::List{T}, inCompFunc::CompFunc)  where {T}
  local outUnion::List{T} = nil

  for e in inList1
    outUnion = unionEltOnTrue(e, outUnion, inCompFunc)
  end
  for e in inList2
    outUnion = unionEltOnTrue(e, outUnion, inCompFunc)
  end
  outUnion = listReverseInPlace(outUnion)
  outUnion
end

function unionAppendListOnTrue(inList::List{T}, inUnion::List{T}, inCompFunc::CompFunc)  where {T}
  local outUnion::List{T}

  outUnion = fold(inList, (inCompFunc) -> unionEltOnTrue(inCompFunc = inCompFunc), inUnion)
  outUnion
end

#= Takes a list of lists and returns the union of the sublists.
Example: unionList({1}, {1, 2}, {3, 4}, {5}}) => {1, 2, 3, 4, 5} =#
function unionList(inList::List{List{T}})  where {T}
  local outUnion::List{T}

  outUnion = if listEmpty(inList)
    nil
  else
    reduce(inList, union)
  end
  outUnion
end

#= Takes a list of lists and a comparison function over two elements of the
lists. It returns the union of all sublists using the comparison function
for identity.
Example:
unionOnTrueList({{1}, {1, 2}, {3, 4}}, intEq) => {1, 2, 3, 4} =#
function unionOnTrueList(inList::List{List{T}}, inCompFunc::CompFunc)  where {T}
  local outUnion::List{T}
  outUnion = if listEmpty(inList)
    nil
  else
    reduce1(inList, unionOnTrue, inCompFunc)
  end
  outUnion
end

#= Takes a list and a function, and creates a new list by applying the function
to each element of the list. =#
function map(inList::List{TI}, inFunc::MapFunc)  where {TI}
  list(inFunc(e) for e in inList)
end

#= Takes a list and a function, and creates a new list by applying the function
to each element of the list. =#
function mapCheckReferenceEq(inList::List{TI}, inFunc::MapFunc)  where {TI}
  #=TODO=#
end

#= Takes a list and a function, and creates a new list by applying the function
to each element of the list. The created list will be reversed compared to
the given list. =#
function mapReverse(inList::List{TI}, inFunc::MapFunc)  where {TI}
  listReverse(inFunc(e) for e in inList)
end

#= Takes a list and a function, and creates two new lists by applying the
function to each element of the list. =#
function map_2(inList::List{TI}, inFunc::MapFunc)  where {TI, T2}
  local outList2::List = nil
  local outList1::List = nil
  local e1
  local e2
  for e in inList
    (e1, e2) = inFunc(e)
    outList1 = e1 <| outList1
    if isPresent(outList2)
      outList2 = e2 <| outList2
    end
  end
  outList1 = listReverseInPlace(outList1)
  if isPresent(outList2)
    outList2 = listReverseInPlace(outList2)
  end
  (outList1, outList2)
end

#= Takes a list and a function, and creates three new lists by applying the
function to each element of the list. =#
function map_3(inList::List{TI}, inFunc::MapFunc)  where {TI}
  local outList3::List = nil
  local outList2::List = nil
  local outList1 = nil

  local e1
  local e2
  local e3

  for e in inList
    (e1, e2, e3) = inFunc(e)
    outList1 = e1 <| outList1
    if isPresent(outList2)
      outList2 = e2 <| outList2
    end
    if isPresent(outList3)
      outList3 = e3 <| outList3
    end
  end
  outList1 = listReverseInPlace(outList1)
  if isPresent(outList2)
    outList2 = listReverseInPlace(outList2)
  end
  if isPresent(outList3)
    outList3 = listReverseInPlace(outList3)
  end
  (outList1, outList2, outList3)
end

#= The same as map(map(inList, getOption), inMapFunc), but is more efficient and
it strips out NONE() instead of failing on them. =#
function mapOption(inList::List{Option{TI}}, inFunc::MapFunc)  where {TI}
  local outList::List = nil

  local ei::TI
  local eo

  for oe in inList
    if ! isNone(oe)
      @match SOME(ei) = oe
      eo = inFunc(ei)
      outList = eo <| outList
    end
  end
  outList = listReverseInPlace(outList)
  outList
end

#= The same as map1(map(inList, getOption), inMapFunc), but is more efficient and
it strips out NONE() instead of failing on them. =#
function map1Option(inList::List{Option{TI}}, inFunc::MapFunc, inArg1::ArgT)  where {TI, ArgT}
  local outList::List = nil

  local ei::TI
  local eo

  for oe in inList
    if ! isNone(oe)
      @match SOME(ei) = oe
      eo = inFunc(ei, inArg1)
      outList = eo <| outList
    end
  end
  outList = listReverseInPlace(outList)
  outList
end

#= The same as map2(map(inList, getOption), inMapFunc), but is more efficient and
it strips out NONE() instead of failing on them. =#
function map2Option(inList::List{Option{TI}}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  local outList::List = nil

  local ei::TI
  local eo

  for oe in inList
    if isSome(oe)
      @match SOME(ei) = oe
      eo = inFunc(ei, inArg1, inArg2)
      outList = eo <| outList
    end
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Takes a list and a function which does not return a value. The function is
probably a function with side effects, like print. =#
function map_0(inList::List{T}, inFunc::MapFunc)  where {T}
  for e in inList
    inFunc(e)
  end
end

#= Takes a list, a function and one extra argument, and creates a new list
by applying the function to each element of the list. =#
function map1(inList::List{TI}, inMapFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  list(inMapFunc(e, inArg1) for e in inList)
end

#= Takes a list, a function and one extra argument, and creates a new list
by applying the function to each element of the list. The created list will
be reversed compared to the given list. =#
function map1Reverse(inList::List{TI}, inMapFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  listReverse(inMapFunc(e, inArg1) for e in inList)
end

#= Takes a list, a function and one extra argument, and creates a new list
by applying the function to each element of the list. The given map
function has it's arguments reversed compared to map1. =#
function map1r(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  list(inFunc(inArg1, e) for e in inList)
end

#= Takes a list, a function and one extra argument, and applies the functions to
each element of the list. =#
function map1_0(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  for e in inList
    inFunc(e, inArg1)
  end
end

#= Takes a list and a function, and creates two new lists by applying the
function to each element of the list. =#
function map1_2(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  local outList2::List = nil
  local outList1::List = nil
  local e1
  local e2
  for e in inList
    (e1, e2) = inFunc(e, inArg1)
    outList1 = e1 <| outList1
    outList2 = e2 <| outList2
  end
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  (outList1, outList2)
end

#= Takes a list and a function, and creates three new lists by applying the
function to each element of the list. =#
function map1_3(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  local outList3::List = nil
  local outList2::List = nil
  local outList1 = nil
  local e1
  local e2
  local e3
  for e in inList
    (e1, e2, e3) = inFunc(e, inArg1)
    outList1 = e1 <| outList1
    outList2 = e2 <| outList2
    outList3 = e3 <| outList3
  end
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  outList3 = listReverseInPlace(outList3)
  (outList1, outList2, outList3)
end

#= Takes a list, a function and two extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map2(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  local outList::List
  outList = list(inFunc(e, inArg1, inArg2) for e in inList)
end

#= Takes a list, a function and two extra arguments, and creates a new list
by applying the function to each element of the list. The created list will
be reversed compared to the given list. =#
function map2Reverse(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  local outList::List
  outList = listReverse(inFunc(e, inArg1, inArg2) for e in inList)
  outList
end

#= Takes a list, a function and two extra argument, and creates a new list
by applying the function to each element of the list. The given map
function has it's arguments in another order compared to map2 and map2r. =#
function map2rm(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  local outList::List

  outList = list(inFunc(inArg1, e, inArg2) for e in inList)
  outList
end

#= Takes a list, a function and two extra argument, and creates a new list
by applying the function to each element of the list. The given map
function has it's arguments reversed compared to map2. =#
function map2r(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  local outList::List

  outList = list(inFunc(inArg1, inArg2, e) for e in inList)
  outList
end

#= Takes a list, a function and two extra argument, and applies the functions to
each element of the list. =#
function map2_0(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  for e in inList
    inFunc(e, inArg1, inArg2)
  end
end

#= Takes a list, a function and two extra argument, and creates two new lists
by applying the function to each element of the list. =#
function map2_2(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  local outList2::List = nil
  local outList1::List = nil

  local e1
  local e2

  for e in inList
    (e1, e2) = inFunc(e, inArg1, inArg2)
    outList1 = e1 <| outList1
    outList2 = e2 <| outList2
  end
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  (outList1, outList2)
end

#= Takes a list, a function and two extra argument, and creates three new lists
by applying the function to each element of the list. =#
function map2_3(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  local outList3::List = nil
  local outList2::List = nil
  local outList1 = nil
  local e1
  local e2
  local e3
  for e in inList
    (e1, e2, e3) = inFunc(e, inArg1, inArg2)
    outList1 = e1 <| outList1
    outList2 = e2 <| outList2
    outList3 = e3 <| outList3
  end
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  outList3 = listReverseInPlace(outList3)
  (outList1, outList2, outList3)
end

#= Takes a list, a function and three extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map3(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)  where {TI, ArgT1, ArgT2, ArgT3}
  local outList::List

  outList = list(inFunc(e, inArg1, inArg2, inArg3) for e in inList)
  outList
end

#= Takes a list, a function and three extra argument, and creates a new list
by applying the function to each element of the list. The given map
function has it's arguments reversed compared to map3. =#
function map3r(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)  where {TI, ArgT1, ArgT2, ArgT3}
  local outList::List

  outList = list(inFunc(inArg1, inArg2, inArg3, e) for e in inList)
  outList
end

#= Takes a list, a function and three extra argument, and applies the functions to
each element of the list. =#
function map3_0(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)  where {TI, ArgT1, ArgT2, ArgT3}
  for e in inList
    inFunc(e, inArg1, inArg2, inArg3)
  end
end

#= Takes a list, a function and three extra argument, and creates two new lists
by applying the function to each element of the list. =#
function map3_2(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)  where {TI, ArgT1, ArgT2, ArgT3}
  local outList2::List = nil
  local outList1 = nil

  local e1
  local e2

  for e in inList
    (e1, e2) = inFunc(e, inArg1, inArg2, inArg3)
    outList1 = e1 <| outList1
    outList2 = e2 <| outList2
  end
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  (outList1, outList2)
end

#= Takes a list, a function and four extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map4(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4)  where {TI, ArgT1, ArgT2, ArgT3, ArgT4}
  local outList::List

  outList = list(inFunc(e, inArg1, inArg2, inArg3, inArg4) for e in inList)
  outList
end

#= Takes a list, a function and four extra arguments, and applies the functions to
each element of the list. =#
function map4_0(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4)  where {TI, ArgT1, ArgT2, ArgT3, ArgT4}
  for e in inList
    inFunc(e, inArg1, inArg2, inArg3, inArg4)
  end
end

#= Takes a list, a function and three extra argument, and creates two new lists
by applying the function to each element of the list. =#
function map4_2(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4)  where {TI, ArgT1, ArgT2, ArgT3, ArgT4}
  local outList2::List = nil
  local outList1 = nil

  local e1
  local e2

  for e in inList
    (e1, e2) = inFunc(e, inArg1, inArg2, inArg3, inArg4)
    outList1 = e1 <| outList1
    outList2 = e2 <| outList2
  end
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  (outList1, outList2)
end

#= Takes a list, a function and five extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map5(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5)  where {TI, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5}
  local outList::List

  outList = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5) for e in inList)
  outList
end

#= Takes a list, a function and six extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map6(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6)  where {TI, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6}
  local outList::List

  outList = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6) for e in inList)
  outList
end

#= Takes a list, a function and seven extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map7(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6, inArg7::ArgT7)  where {TI, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6, ArgT7}
  local outList::List

  outList = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7) for e in inList)
  outList
end

#= Takes a list, a function and eight extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map8(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6, inArg7::ArgT7, inArg8::ArgT8)  where {TI, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6, ArgT7, ArgT8}
  local outList::List

  outList = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8) for e in inList)
  outList
end

#= Takes a list, a function and nine extra arguments, and creates a new list
by applying the function to each element of the list. =#
function map9(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inArg5::ArgT5, inArg6::ArgT6, inArg7::ArgT7, inArg8::ArgT8, inArg9::ArgT9)  where {TI, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6, ArgT7, ArgT8, ArgT9}
  local outList::List

  outList = list(inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5, inArg6, inArg7, inArg8, inArg9) for e in inList)
  outList
end

#= Takes a list and a function that maps elements to lists, which are flattened
into one list. Example (fill2(n) = {n, n}):
mapFlat({1, 2, 3}, fill2) => {1, 1, 2, 2, 3, 3} =#
function mapFlat(inList::List{TI}, inMapFunc::MapFunc)  where {TI}
  local outList::List

  outList = listReverse(mapFlatReverse(inList, inMapFunc))
  outList
end

#= Takes a list and a function that maps elements to lists, which are flattened
into one list. Returns the values in reverse order as the input.
Example (fill2(n) = {n, n}):
mapFlat({1, 2, 3}, fill2) => {3, 3, 2, 2, 1, 1} =#
function mapFlatReverse(inList::List{TI}, inMapFunc::MapFunc)  where {TI}
  local outList::List = nil

  for e in inList
    outList = listAppend(inMapFunc(e), outList)
  end
  outList
end

#= Takes a list and a function that maps elements to lists, which are flattened
into one list. This function also takes an extra argument that is passed to
the mapping function. =#
function map1Flat(inList::List{TI}, inMapFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  local outList::List = nil

  for e in inList
    outList = listAppend(inMapFunc(e, inArg1), outList)
  end
  outList = listReverseInPlace(outList)
end

#= Takes a list and a function that maps elements to lists, which are flattened
into one list. This function also takes two extra arguments that are passed
to the mapping function. =#
function map2Flat(inList::List{TI}, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  local outList::List = nil

  for e in inList
    outList = listAppend(inMapFunc(e, inArg1, inArg2), outList)
  end
  outList = listReverseInPlace(outList)
  outList
end

#= More efficient than: map(map(inList, inMapFunc1), inMapFunc2) =#
function mapMap(inList::List{TI}, inMapFunc1::MapFunc1, inMapFunc2::MapFunc2)  where {TI}
  local outList::List

  outList = list(inMapFunc2(inMapFunc1(e)) for e in inList)
  outList
end

#= More efficient than map_0(map(inList, inMapFunc1), inMapFunc2), =#
function mapMap_0(inList::List{TI}, inMapFunc1::MapFunc1, inMapFunc2::MapFunc2)  where {TI}
  for e in inList
    inMapFunc2(inMapFunc1(e))
  end
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. =#
function mapAllValue(inList::List{TI}, inMapFunc::MapFunc, inValue::VT)  where {TI, VT}
  local eo::TO

  for e in inList
    eo = inMapFunc(e)
    @match true = valueEq(eo, inValue)
  end
end

#= Same as mapAllValue, but returns true or false instead of succeeding or
failing. =#
function mapAllValueBool(inList::List{TI}, inMapFunc::MapFunc, inValue::VT)  where {TI, VT}
  local outAllValue::Bool

  try
    mapAllValue(inList, inMapFunc, inValue)
    outAllValue = true
  catch
    outAllValue = false
  end
  outAllValue
end

#= Same as mapAllValueBool, but takes one extra argument. =#
function map1AllValueBool(inList::List{TI}, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1)  where {TI, VT, ArgT1}
  local outAllValue::Bool

  try
    map1AllValue(inList, inMapFunc, inValue, inArg1)
    outAllValue = true
  catch
    outAllValue = false
  end
  outAllValue
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. This function also takes an extra
argument that are passed to the mapping function. =#
function map1AllValue(inList::List{TI}, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1)  where {TI, VT, ArgT1}
  local eo::TO

  for e in inList
    eo = inMapFunc(e, inArg1)
    @match true = valueEq(eo, inValue)
  end
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. This function also takes an extra
argument that are passed to the mapping function. =#
function map1rAllValue(inList::List{TI}, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1)  where {TI, VT, ArgT1}
  local eo::TO

  for e in inList
    eo = inMapFunc(inArg1, e)
    @match true = valueEq(eo, inValue)
  end
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. This function also takes two extra
arguments that are passed to the mapping function. =#
function map2AllValue(inList::List{TI}, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1, inArg2::ArgT2)  where {TI, VT, ArgT1, ArgT2}
  local eo::TO

  for e in inList
    eo = inMapFunc(e, inArg1, inArg2)
    @match true = valueEq(eo, inValue)
  end
end

#= Same as mapAllValue, but returns true or false instead of succeeding or
failing. =#
function mapListAllValueBool(inList::List{List{TI}}, inMapFunc::MapFunc, inValue::VT)  where {TI, VT}
  local outAllValue::Bool = true

  for lst in inList
    if ! mapAllValueBool(lst, inMapFunc, inValue)
      outAllValue = false
      return outAllValue
    end
  end
  outAllValue
end

#= Same as mapListAllValueBool, but takes one extra argument. =#
function map1ListAllValueBool(inList::List{List{TI}}, inMapFunc::MapFunc, inValue::VT, inArg1::ArgT1)  where {TI, VT, ArgT1}
  local outAllValue::Bool = true

  for lst in inList
    if ! map1AllValueBool(lst, inMapFunc, inValue, inArg1)
      outAllValue = false
      return outAllValue
    end
  end
  outAllValue
end

#= Applies a function to all elements in the lists, and fails if not all
elements are equal to the given value. This function also takes an extra
argument that are passed to the mapping function and updated =#
function foldAllValue(inList::List{TI}, inMapFunc::MapFunc, inValue::TO, inArg1::ArgT1)  where {TI, TO, ArgT1}
  local arg::ArgT1 = inArg1
  local eo::TO

  for e in inList
    (eo, arg) = inMapFunc(e, arg)
    @match true = valueEq(eo, inValue)
  end
end

#= fold(map(inList, inApplyFunc), inFoldFunc, inFoldArg), but is more
memory-efficient. =#
function applyAndFold(inList::List{TI}, inFoldFunc::FoldFunc, inApplyFunc::ApplyFunc, inFoldArg::FT)  where {TI, FT}
  local outResult::FT = inFoldArg

  for e in inList
    outResult = inFoldFunc(inApplyFunc(e), outResult)
  end
  outResult
end

#= fold(map(inList, inApplyFunc(inExtraArg)), inFoldFunc, inFoldArg), but is more
memory-efficient. =#
function applyAndFold1(inList::List{TI}, inFoldFunc::FoldFunc, inApplyFunc::ApplyFunc, inExtraArg::ArgT1, inFoldArg::FT)  where {TI, FT, ArgT1}
  local outResult::FT = inFoldArg
  for e in inList
    outResult = inFoldFunc(inApplyFunc(e, inExtraArg), outResult)
  end
  outResult
end

#= Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value. =#
function mapBoolOr(inList::List{TI}, inFunc::MapFunc)  where {TI, ArgT1}
  local res::Bool = false

  for e in inList
    if inFunc(e)
      res = true
      return res
    end
  end
  res
end

#= Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value. =#
function mapBoolAnd(inList::List{TI}, inFunc::MapFunc)  where {TI}
  local res::Bool = false

  for e in inList
    if ! inFunc(e)
      return res
    end
  end
  res = true
  res
end

#= Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value. =#
function mapMapBoolAnd(inList::List{TI}, inFunc::MapFunc, inBFunc::MapBFunc)  where {TI, TI2}
  local res::Bool = false

  for e in inList
    if ! inBFunc(inFunc(e))
      return res
    end
  end
  res = true
  res
end

#= Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value.
inFunc takes one additional argument. =#
function map1BoolOr(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  local res::Bool = false

  for e in inList
    if inFunc(e, inArg1)
      res = true
      return res
    end
  end
  res
end

#= Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of false return value.
inFunc takes one additional argument. =#
function map1BoolAnd(inList::List{TI}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  local res::Bool = false

  for e in inList
    if ! inFunc(e, inArg1)
      return res
    end
  end
  res = true
  res
end

#= Maps each element of a inList to Boolean type with inFunc. Stops mapping at first occurrence of true return value.
inFunc takes one additional argument. =#
function map1ListBoolOr(inListList::List{List{TI}}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  local res::Bool = false

  for el in inListList
    for e in el
      if inFunc(e, inArg1)
        res = true
        return res
      end
    end
  end
  res
end

#= Takes a list of lists and a functions, and creates a new list of lists by
applying the function to all elements in  the list of lists.
Example: mapList({{1, 2},{3},{4}}, intString) =>
{{\\\"1\\\", \\\"2\\\"}, {\\\"3\\\"}, {\\\"4\\\"}} =#
function mapList(inListList::List{List{TI}}, inFunc::MapFunc)  where {TI}
  local outListList::List{List}

  outListList = list(list(inFunc(e) for e in lst) for lst in inListList)
  outListList
end

#= Takes a list of lists and a functions, and applying
the function to all elements in  the list of lists.
Example: mapList0({{1, 2},{3},{4}}, print) =#
function mapList0(inListList::List{List{TI}}, inFunc::MapFunc)  where {TI}
  map1_0(inListList, map_0, inFunc)
end

#= Takes a list of lists and a functions, and applying
the function to all elements in  the list of lists.
Example: mapList1_0({{1, 2},{3},{4}}, costomPrint, inArg1) =#
function mapList1_0(inListList::List{List{TI}}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  map2_0(inListList, map1_0, inFunc, inArg1)
end

#= Takes a list of lists and a functions, and applying
the function to all elements in  the list of lists.
Example: mapList1_0({{1, 2},{3},{4}}, costomPrint, inArg1, inArg2) =#
function mapList2_0(inListList::List{List{TI}}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  map3_0(inListList, map2_0, inFunc, inArg1, inArg2)
end

#= Takes a list of lists and a functions, and applying
the function to all elements in  the list of lists.
Example: mapList1_0({{1, 2},{3},{4}}, customPrint, inArg1) =#
function mapList1_1(inListList::List{List{TI}}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  local outListList::List{List}

  outListList = list(list(inFunc(e, inArg1) for e in lst) for lst in inListList)
  outListList
end

#= Takes a list of lists and a functions, and creates a new list of lists by
applying the function to all elements in  the list of lists. The order of the
elements in the inner lists will be reversed compared to mapList.
Example: mapListReverse({{1, 2}, {3}, {4}}, intString) =>
{{\\\"4\\\"}, {\\\"3\\\"}, {\\\"2\\\", \\\"1\\\"}} =#
function mapListReverse(inListList::List{List{TI}}, inFunc::MapFunc)  where {TI}
  local outListList::List{List}

  outListList = list(listReverse(inFunc(e) for e in lst) for lst in inListList)
  outListList
end

#= Similar to mapList but with a mapping function that takes an extra argument. =#
function map1List(inListList::List{List{TI}}, inFunc::MapFunc, inArg1::ArgT1)  where {TI, ArgT1}
  local outListList::List{List}

  outListList = list(list(inFunc(e, inArg1) for e in lst) for lst in inListList)
  outListList
end

#= Similar to mapList but with a mapping function that takes two extra arguments. =#
function map2List(inListList::List{List{TI}}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {TI, ArgT1, ArgT2}
  local outListList::List{List}

  outListList = list(list(inFunc(e, inArg1, inArg2) for e in lst) for lst in inListList)
  outListList
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function. fold will call
the function for each element in a sequence, updating the start value.
Example: fold({1, 2, 3}, intAdd, 2) => 8
intAdd(1, 2) => 3, intAdd(2, 3) => 5, intAdd(3, 5) => 8 =#
function fold(inList::List{T}, inFoldFunc::FoldFunc, inStartValue::FT)  where {T, FT}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(e, outResult)
  end
  outResult
end

#= Same as fold, but with reversed order on the fold function arguments. =#
function foldr(inList::List{T}, inFoldFunc::FoldFunc, inStartValue::FT)  where {T, FT}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(outResult, e)
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and a constant
argument that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold1(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg::ArgT1, inStartValue::FT)  where {T, FT, ArgT1}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(e, inExtraArg, outResult)
  end
  outResult
end

#= Same as fold1, but with reversed order on the fold function arguments. =#
function fold1r(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg::ArgT1, inStartValue::FT)  where {T, FT, ArgT1}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(outResult, e, inExtraArg)
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and two constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold2(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inStartValue::FT)  where {T, FT, ArgT1, ArgT2}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, outResult)
  end
  outResult
end

#= Takes a list and a function operating on list elements having three extra
arguments that is 'updated', thus returned from the function, and three constant
arguments that are not updated. fold will call the function for each element in
a sequence, updating the start values. =#
function fold22(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inStartValue1::FT1, inStartValue2::FT2)  where {T, FT1, FT2, ArgT1, ArgT2}
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inList
    (outResult1, outResult2) = inFoldFunc(e, inExtraArg1, inExtraArg2, outResult1, outResult2)
  end
  (outResult1, outResult2)
end

function foldList(inList::List{List{T}}, inFoldFunc::FoldFunc, inStartValue::FT)  where {T, FT}
  local outResult::FT = inStartValue

  for lst in inList
    for e in lst
      outResult = inFoldFunc(e, outResult)
    end
  end
  outResult
end

function foldList1(inList::List{List{T}}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inStartValue::FT)  where {T, FT, ArgT1}
  local outResult::FT = inStartValue

  for lst in inList
    for e in lst
      outResult = inFoldFunc(e, inExtraArg1, outResult)
    end
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and two constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function foldList2(inList::List{List{T}}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inStartValue::FT)  where {T, FT, ArgT1, ArgT2}
  local outResult::FT = inStartValue

  for lst in inList
    for e in lst
      outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, outResult)
    end
  end
  outResult
end

#= Same as fold2, but with reversed order on the fold function arguments. =#
function fold2r(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inStartValue::FT)  where {T, FT, ArgT1, ArgT2}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(outResult, e, inExtraArg1, inExtraArg2)
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and three constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold3(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inStartValue::FT)  where {T, FT, ArgT1, ArgT2, ArgT3}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, outResult)
  end
  outResult
end

#= Same as fold3, but with reversed order on the fold function arguments. =#
function fold3r(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inStartValue::FT)  where {T, FT, ArgT1, ArgT2, ArgT3}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(outResult, e, inExtraArg1, inExtraArg2, inExtraArg3)
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and four constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold4(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inExtraArg4::ArgT4, inStartValue::FT)  where {T, FT, ArgT1, ArgT2, ArgT3, ArgT4}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, outResult)
  end
  outResult
end

#= Takes a list and a function operating on list elements having three extra
arguments that is 'updated', thus returned from the function, and three constant
arguments that are not updated. fold will call the function for each element in
a sequence, updating the start values. =#
function fold43(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inExtraArg4::ArgT4, inStartValue1::FT1, inStartValue2::FT2, inStartValue3::FT3)  where {T, FT1, FT2, FT3, ArgT1, ArgT2, ArgT3, ArgT4}
  local outResult3::FT3 = inStartValue3
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inList
    (outResult1, outResult2, outResult3) = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, outResult1, outResult2, outResult3)
  end
  (outResult1, outResult2, outResult3)
end

#= Takes a list and a function operating on list elements having two extra
arguments that are 'updated', thus returned from the function. fold will call
the function for each element in a sequence, updating the start value. =#
function fold20(inList::List{T}, inFoldFunc::FoldFunc, inStartValue1::FT1, inStartValue2::FT2)  where {T, FT1, FT2}
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inList
    (outResult1, outResult2) = inFoldFunc(e, outResult1, outResult2)
  end
  (outResult1, outResult2)
end

#= Takes a list and a function operating on list elements having three extra
arguments that are 'updated', thus returned from the function. fold will call
the function for each element in a sequence, updating the start value. =#
function fold30(inList::List{T}, inFoldFunc::FoldFunc, inStartValue1::FT1, inStartValue2::FT2, inStartValue3::FT3)  where {T, FT1, FT2, FT3}
  local outResult3::FT3 = inStartValue3
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inList
    (outResult1, outResult2, outResult3) = inFoldFunc(e, outResult1, outResult2, outResult3)
  end
  (outResult1, outResult2, outResult3)
end

#= Takes a list and a function operating on list elements having two extra
argument that are 'updated', thus returned from the function, and one constant
argument that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold21(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inStartValue1::FT1, inStartValue2::FT2)  where {T, FT1, FT2, ArgT1}
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inList
    (outResult1, outResult2) = inFoldFunc(e, inExtraArg1, outResult1, outResult2)
  end
  (outResult1, outResult2)
end

#= Takes a list and a function operating on list elements having three extra
argument that are 'updated', thus returned from the function, and one constant
argument that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold31(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inStartValue1::FT1, inStartValue2::FT2, inStartValue3::FT3)  where {T, FT1, FT2, FT3, ArgT1}
  local outResult3::FT3 = inStartValue3
  local outResult2::FT2 = inStartValue2
  local outResult1::FT1 = inStartValue1

  for e in inList
    (outResult1, outResult2, outResult3) = inFoldFunc(e, inExtraArg1, outResult1, outResult2, outResult3)
  end
  (outResult1, outResult2, outResult3)
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and five constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold5(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inExtraArg4::ArgT4, inExtraArg5::ArgT5, inStartValue::FT)  where {T, FT, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, outResult)
  end
  outResult
end

#= Takes a list and a function operating on list elements having an extra
argument that is 'updated', thus returned from the function, and six constant
arguments that is not updated. fold will call the function for each element in
a sequence, updating the start value. =#
function fold6(inList::List{T}, inFoldFunc::FoldFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2, inExtraArg3::ArgT3, inExtraArg4::ArgT4, inExtraArg5::ArgT5, inExtraArg6::ArgT6, inStartValue::FT)  where {T, FT, ArgT1, ArgT2, ArgT3, ArgT4, ArgT5, ArgT6}
  local outResult::FT = inStartValue

  for e in inList
    outResult = inFoldFunc(e, inExtraArg1, inExtraArg2, inExtraArg3, inExtraArg4, inExtraArg5, inExtraArg6, outResult)
  end
  outResult
end

#= Takes a list, an extra argument and a function. The function will be applied
to each element in the list, and the extra argument will be passed to the
function and updated. =#
function mapFold(inList::List{TI}, inFunc::FuncType, inArg::FT)  where {TI, FT}
  local outArg::FT = inArg
  local outList::List = nil

  local res::TO

  for e in inList
    (res, outArg) = inFunc(e, outArg)
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, outArg)
end

#= Takes a list, a function, and two extra arguments. The function will be applied
to each element in the list, and the extra arguments will be passed to the
function and updated. =#
function mapFold2(inList::List{TI}, inFunc::FuncType, inArg1::FT1, inArg2::FT2)  where {TI, FT1, FT2}
  local outArg2::FT2 = inArg2
  local outArg1::FT1 = inArg1
  local outList::List = nil

  local res::TO

  for e in inList
    (res, outArg1, outArg2) = inFunc(e, outArg1, outArg2)
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, outArg1, outArg2)
end

#= Takes a list, a function, and three extra arguments. The function will be applied
to each element in the list, and the extra arguments will be passed to the
function and updated. =#
function mapFold3(inList::List{TI}, inFunc::FuncType, inArg1::FT1, inArg2::FT2, inArg3::FT3)  where {TI, FT1, FT2, FT3}



  local outList::List = nil

  local res::TO

  for e in inList
    (res, inArg1, inArg2, inArg3) = inFunc(e, inArg1, inArg2, inArg3)
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, inArg1, inArg2, inArg3)
end

#= Takes a list, a function, and four extra arguments. The function will be applied
to each element in the list, and the extra arguments will be passed to the
function and updated. =#
function mapFold4(inList::List{TI}, inFunc::FuncType, inArg1::FT1, inArg2::FT2, inArg3::FT3, inArg4::FT4)  where {TI, FT1, FT2, FT3, FT4}




  local outList::List = nil

  local res::TO

  for e in inList
    (res, inArg1, inArg2, inArg3, inArg4) = inFunc(e, inArg1, inArg2, inArg3, inArg4)
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, inArg1, inArg2, inArg3, inArg4)
end

#= Takes a list, a function, and five extra arguments. The function will be applied
to each element in the list, and the extra arguments will be passed to the
function and updated. =#
function mapFold5(inList::List{TI}, inFunc::FuncType, inArg1::FT1, inArg2::FT2, inArg3::FT3, inArg4::FT4, inArg5::FT5)  where {TI, FT1, FT2, FT3, FT4, FT5}





  local outList::List = nil

  local res::TO

  for e in inList
    (res, inArg1, inArg2, inArg3, inArg4, inArg5) = inFunc(e, inArg1, inArg2, inArg3, inArg4, inArg5)
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, inArg1, inArg2, inArg3, inArg4, inArg5)
end

#= Takes a list, an extra argument, an extra constant argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map1Fold(inList::List{TI}, inFunc::FuncType, inConstArg::ArgT1, inArg::FT)  where {TI, FT, ArgT1}
  local outArg::FT = inArg
  local outList::List = nil

  local res::TO

  for e in inList
    (res, outArg) = inFunc(e, inConstArg, outArg)
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, outArg)
end

#= Takes a list, two extra constant arguments, an extra argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map2Fold(inList::List{TI}, inFunc::FuncType, inConstArg::ArgT1, inConstArg2::ArgT2, inArg::FT, inAccum::List = nil)  where {TI, FT, ArgT1, ArgT2}
  local outArg::FT = inArg
  local outList::List = inAccum

  local res::TO

  for e in inList
    (res, outArg) = inFunc(e, inConstArg, inConstArg2, outArg)
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, outArg)
end

#= Takes a list, two extra constant arguments, an extra argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map2FoldCheckReferenceEq(inList::List{TIO}, inFunc::FuncType, inConstArg::ArgT1, inConstArg2::ArgT2, inArg::FT)  where {TIO, FT, ArgT1, ArgT2}
  #= Todo =#
end

#= Takes a list, three extra constant arguments, an extra argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map3Fold(inList::List{TI}, inFunc::FuncType, inConstArg::ArgT1, inConstArg2::ArgT2, inConstArg3::ArgT3, inArg::FT)  where {TI, FT, ArgT1, ArgT2, ArgT3}
  local outArg::FT = inArg
  local outList::List = nil

  local res::TO

  for e in inList
    (res, outArg) = inFunc(e, inConstArg, inConstArg2, inConstArg3, outArg)
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, outArg)
end

#= Takes a list, four extra constant arguments, an extra argument, and a function.
The function will be applied to each element in the list, and the extra
argument will be passed to the function and updated. =#
function map4Fold(inList::List{TI}, inFunc::FuncType, inConstArg::ArgT1, inConstArg2::ArgT2, inConstArg3::ArgT3, inConstArg4::ArgT4, inArg::FT)  where {TI, FT, ArgT1, ArgT2, ArgT3, ArgT4}
  local outArg::FT = inArg
  local outList::List = nil

  local res::TO

  for e in inList
    (res, outArg) = inFunc(e, inConstArg, inConstArg2, inConstArg3, inConstArg4, outArg)
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, outArg)
end

#= Takes a list, an extra argument and a function. The function will be applied
to each element in the list, and the extra argument will be passed to the
function and updated. The input and outputs of the function are joined as
tuples. =#
function mapFoldTuple(inList::List{TI}, inFunc::FuncType, inArg::FT)  where {TI, FT}
  local outArg::FT = inArg
  local outList::List = nil
  local res::TO

  for e in inList
    (res, outArg) = inFunc((e, outArg))
    outList = res <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, outArg)
end

#= Takes a list of lists, an extra argument, and a function.  The function will
be applied to each element in the list, and the extra argument will be passed
to the function and updated for each element. =#
function mapFoldList(inListList::List{List{TI}}, inFunc::FuncType, inArg::FT)  where {TI, FT}
  local outArg::FT = inArg
  local outListList::List{List} = nil

  local res::List

  for lst in inListList
    (res, outArg) = mapFold(lst, inFunc, outArg)
    outListList = res <| outListList
  end
  outListList = listReverseInPlace(outListList)
  (outListList, outArg)
end

#= Takes a list of lists, an extra argument, and a function.  The function will
be applied to each element in the list, and the extra argument will be passed
to the function and updated for each element. =#
function map3FoldList(inListList::List{List{TI}}, inFunc::FuncType, inConstArg1::ArgT1, inConstArg2::ArgT2, inConstArg3::ArgT3, inArg::FT)  where {TI, FT, ArgT1, ArgT2, ArgT3}
  local outArg::FT = inArg
  local outListList::List{List} = nil

  local res::List

  for lst in inListList
    (res, outArg) = map3Fold(lst, inFunc, inConstArg1, inConstArg2, inConstArg3, inArg)
    outListList = res <| outListList
  end
  outListList = listReverseInPlace(outListList)
  (outListList, outArg)
end

#= Takes a list of lists, an extra argument and a function. The function will be
applied to each element in the list, and the extra argument will be passed to
the function and updated. The input and outputs of the function are joined as
tuples. =#
function mapFoldListTuple(inListList::List{List{TI}}, inFunc::FuncType, inFoldArg::TO)  where {TI, FT, TO}
  local outFoldArg::TO = inFoldArg
  local outListList::List{List} = nil

  local res::List

  for lst in inListList
    (res, outFoldArg) = mapFoldTuple(lst, inFunc, outFoldArg)
    outListList = res <| outListList
  end
  outListList = listReverseInPlace(outListList)
  (outListList, outFoldArg)
end

#= Takes a value and a function operating on the value n times.
Example: foldcallN(1, intAdd, 4) => 4 =#
function foldcallN(n::ModelicaInteger, inFoldFunc::FoldFunc, inStartValue::FT)  where {FT}
  local outResult::FT = inStartValue
  for i in 1:n
    outResult = inFoldFunc(outResult)
  end
  outResult
end

#= Takes a list and a function operating on two elements of the list.
The function performs a reduction of the list to a single value using the
function. Example:
reduce({1, 2, 3}, intAdd) => 6 =#
function reduce(inList::List{T}, inReduceFunc::ReduceFunc)  where {T}
  local outResult::T

  local rest::List{T}

  @match outResult <| rest = inList
  for e in rest
    outResult = inReduceFunc(outResult, e)
  end
  outResult
end

#= Takes a list and a function operating on two elements of the list.
The function performs a reduction of the list to a single value using the
function. This function also takes an extra argument that is sent to the
reduction function. =#
function reduce1(inList::List{T}, inReduceFunc::ReduceFunc, inExtraArg1::ArgT1)  where {T, ArgT1}
  local outResult::T

  local rest::List{T}

  @match outResult <| rest = inList
  for e in rest
    outResult = inReduceFunc(outResult, e, inExtraArg1)
  end
  outResult
end

#= Takes a list of lists and flattens it out, producing one list of all elements
of the sublists. O(len(outList))
Example: flatten({{1, 2}, {3, 4, 5}, {6}, {}}) => {1, 2, 3, 4, 5, 6} =#
function flatten(inList::List{List{T}})  where {T}
  local outList::List{T} = listAppend(lst for lst in listReverse(inList))
  outList
end

function flattenReverse(inList::List{List{T}})  where {T}
  local outList::List{T} = listAppend(lst for lst in inList)
  outList
end

#= Takes two lists of the same type and threads (interleaves) them together.
Example: thread({1, 2, 3}, {4, 5, 6}) => {4, 1, 5, 2, 6, 3} =#
function thread(inList1::List{T}, inList2::List{T}, inAccum::List{T} = nil)  where {T}
  local outList::List{T} = nil

  local e2::T
  local rest_e2::List{T} = inList2

  for e1 in inList1
    @match e2 <| rest_e2 = rest_e2
    outList = e1 <| e2 <| outList
  end
  @match true = listEmpty(rest_e2)
  outList = listReverseInPlace(outList)
  outList
end

#= Takes three lists of the same type and threads (interleaves) them together.
Example: thread({1, 2, 3}, {4, 5, 6}, {7, 8, 9}) =>
{7, 4, 1, 8, 5, 2, 9, 6, 3} =#
function thread3(inList1::List{T}, inList2::List{T}, inList3::List{T})  where {T}
  local outList::List{T} = nil

  local e2::T
  local e3::T
  local rest_e2::List{T} = inList2
  local rest_e3::List{T} = inList3

  for e1 in inList1
    @match e2 <| rest_e2 = rest_e2
    @match e3 <| rest_e3 = rest_e3
    outList = e1 <| e2 <| e3 <| outList
  end
  @match true = listEmpty(rest_e2)
  @match true = listEmpty(rest_e3)
  outList = listReverseInPlace(outList)
  outList
end

#= Takes two lists and threads (interleaves) the arguments into a list of tuples
consisting of the two element types.
Example: threadTuple({1, 2, 3}, {true, false, true}) =>
{(1, true), (2, false), (3, true)} =#
function threadTuple(inList1::List{T1}, inList2::List{T2})  where {T1, T2}
  local outTuples::List{Tuple{T1, T2}}

  outTuples = list(@do_threaded_for (e1, e2) (e1, e2) (inList1, inList2))
  outTuples
end

#= Takes a list of two-element tuples and splits the tuples into two separate
lists. Example: unzip({(1, 2), (3, 4)}) => ({1, 3}, {2, 4}) =#
function unzip(inTuples::List{Tuple{T1, T2}})  where {T1, T2}
  local outList2::List{T2} = nil
  local outList1::List{T1} = nil

  local e1::T1
  local e2::T2

  for tpl in inTuples
    (e1, e2) = tpl
    outList1 = e1 <| outList1
    outList2 = e2 <| outList2
  end
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  (outList1, outList2)
end

#= Like unzip, but returns the lists in reverse order. =#
function unzipReverse(inTuples::List{Tuple{T1, T2}})  where {T1, T2}
  local outList2::List{T2} = nil
  local outList1::List{T1} = nil

  local e1::T1
  local e2::T2

  for tpl in inTuples
    (e1, e2) = tpl
    outList1 = e1 <| outList1
    outList2 = e2 <| outList2
  end
  (outList1, outList2)
end

#= Takes a list of two-element tuples and creates a list from the first element
of each tuple. Example: unzipFirst({(1, 2), (3, 4)}) => {1, 3} =#
function unzipFirst(inTuples::List{Tuple{T1, T2}})  where {T1, T2}
  local outList::List{T1} = nil

  local e::T1

  for tpl in inTuples
    (e, _) = tpl
    outList = e <| outList
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Takes a list of two-element tuples and creates a list from the second element
of each tuple. Example: unzipFirst({(1, 2), (3, 4)}) => {2, 4} =#
function unzipSecond(inTuples::List{Tuple{T1, T2}})  where {T1, T2}
  local outList::List{T2} = nil

  local e::T2

  for tpl in inTuples
    (_, e) = tpl
    outList = e <| outList
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Takes three lists and threads (interleaves) the arguments into a list of tuples
consisting of the three element types. =#
function thread3Tuple(inList1::List{T1}, inList2::List{T2}, inList3::List{T3})  where {T1, T2, T3}
  local outTuples::List{Tuple{T1, T2, T3}}

  outTuples = list(@do_threaded_for (e1, e2, e3) (e1, e2, e3) (inList1, inList2, inList3))
  outTuples
end

#= Takes three lists and threads (interleaves) the arguments into a list of tuples
consisting of the four element types. =#
function thread4Tuple(inList1::List{T1}, inList2::List{T2}, inList3::List{T3}, inList4::List{T4})  where {T1, T2, T3, T4}
  local outTuples::List{Tuple{T1, T2, T3, T4}}

  outTuples = list(@do_threaded_for (e1, e2, e3, e4) (e1, e2, e3, e4) (inList1, inList2, inList3, inList4))
  outTuples
end

#= Takes three lists and threads (interleaves) the arguments into a list of tuples
consisting of the five element types. =#
function thread5Tuple(inList1::List{T1}, inList2::List{T2}, inList3::List{T3}, inList4::List{T4}, inList5::List{T5})  where {T1, T2, T3, T4, T5}
  local outTuples::List{Tuple{T1, T2, T3, T4, T5}}

  outTuples = list(@do_threaded_for (e1, e2, e3, e4, e5) (e1, e2, e3, e4, e5) (inList1, inList2, inList3, inList4, inList5))
  outTuples
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list.
Example: threadMap({1, 2}, {3, 4}, intAdd) => {1+3, 2+4} =#
function threadMap(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc)  where {T1, T2}
  local outList::List

  outList = list(@do_threaded_for inMapFunc(e1, e2) (e1, e2) (inList1, inList2))
  outList
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. The order of the result list
will be reversed compared to the input lists.
Example: threadMap({1, 2}, {3, 4}, intAdd) => {2+4, 1+3} =#
function threadMapReverse(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc)  where {T1, T2}
  local outList::List

  outList = listReverse(@do_threaded_for inMapFunc(e1, e2) (e1, e2) (inList1, inList2))
  outList
end

#= Like threadMap, but returns two lists instead of one. =#
function threadMap_2(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc)  where {T1, T2}
  local outList2::List = nil
  local outList1::List = nil
  local e2::T2
  local rest_e2::List{T2} = inList2
  local ret1
  local ret2
  for e1 in inList1
    @match e2 <| rest_e2 = rest_e2
    (ret1, ret2) = inMapFunc(e1, e2)
    outList1 = ret1 <| outList1
    outList2 = ret2 <| outList2
  end
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  (outList1, outList2)
end

#= Takes two lists of lists and a function and threads (interleaves) and maps
the elements of the two lists, creating a new list.
Example: threadMapList({{1, 2}}, {{3, 4}}, intAdd) => {{1 + 3, 2 + 4}} =#
function threadMapList(inList1::List{List{T1}}, inList2::List{List{T2}}, inMapFunc::MapFunc)  where {T1, T2}
  local outList::List{List}

  outList = list(@do_threaded_for threadMap(lst1, lst2, inMapFunc) (lst1, lst2) (inList1, inList2))
  outList
end

#= Like threadMapList, but returns two lists instead of one. =#
function threadMapList_2(inList1::List{List{T1}}, inList2::List{List{T2}}, inMapFunc::MapFunc)  where {T1, T2}
  local outList2::List{List} = nil
  local outList1::List{} = nil

  local l2::List{T2}
  local rest_l2::List{List{T2}} = inList2
  local ret1::
  local ret2::List

  for l1 in inList1
    @match l2 <| rest_l2 = rest_l2
    (ret1, ret2) = threadMap_2(l1, l2, inMapFunc)
    outList1 = ret1 <| outList1
    outList2 = ret2 <| outList2
  end
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  (outList1, outList2)
end

#= Takes two lists of lists as arguments and produces a list of lists of a two
tuple of the element types of each list.
Example: threadTupleList({{1}, {2, 3}}, {{'a'}, {'b', 'c'}}) =>
{{(1, 'a')}, {(2, 'b'), (3, 'c')}} =#
function threadTupleList(inList1::List{List{T1}}, inList2::List{List{T2}})  where {T1, T2}
  local outList::List{List{Tuple{T1, T2}}}

  outList = list(@do_threaded_for threadTuple(lst1, lst2) (lst1, lst2) (inList1, inList2))
  outList
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, and checks if the result is the same as the given
value.
Example: threadMapAllValue({true, true}, {false, true}, boolAnd, true) =>
fail =#
function threadMapAllValue(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inValue::VT)  where {T1, T2, VT}
  _ = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    local res::TO
    @match (inList1, inList2) begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inMapFunc(e1, e2)
        equality(res, inValue)
        threadMapAllValue(rest1, rest2, inMapFunc, inValue)
        ()
      end

      ( nil(),  nil())  => begin
        ()
      end
    end
  end
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes an
extra arguments that are passed to the mapping function. =#
function threadMap1(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inArg1::ArgT1)  where {T1, T2, ArgT1}
  list(@do_threaded_for inMapFunc(e1, e2, inArg1) (e1, e2) (inList1, inList2))
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes an
extra arguments that are passed to the mapping function. The order of the
result list will be reversed compared to the input lists. =#
function threadMap1Reverse(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inArg1::ArgT1)  where {T1, T2, ArgT1}
  listReverse(@do_threaded_for inMapFunc(e1, e2, inArg1) (e1, e2) (inList1, inList2))
end

#= Takes two lists and a function, and applies the function to each element of
the lists in a pairwise fashion. This function also takes an extra argument
which is passed to the mapping function, but returns no result. =#
function threadMap1_0(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inArg1::ArgT1)  where {T1, T2, ArgT1}
  _ = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    @match (inList1, inList2, inMapFunc, inArg1) begin
      ( nil(),  nil(), _, _)  => begin
        ()
      end

      (e1 <| rest1, e2 <| rest2, _, _)  => begin
        inMapFunc(e1, e2, inArg1)
        threadMap1_0(rest1, rest2, inMapFunc, inArg1)
        ()
      end
    end
  end
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes two
extra arguments that are passed to the mapping function. =#
function threadMap2(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {T1, T2, ArgT1, ArgT2}
  list(@do_threaded_for inMapFunc(e1, e2, inArg1, inArg2) (e1, e2) (inList1, inList2))
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes two
extra arguments that are passed to the mapping function. The order of the
result list will be reversed compared to the input lists. =#
function threadMap2Reverse(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2)  where {T1, T2, ArgT1, ArgT2}
  outList = listReverse(@do_threaded_for inMapFunc(e1, e2, inArg1, inArg2) (e1, e2) (inList1, inList2))
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes two
extra arguments and a fold argument that are passed to the mapping function.
The order of the result list will be reversed compared to the input lists. =#
function threadMap2ReverseFold(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inFoldArg::FT, inAccum::List = nil)  where {T1, T2, FT, ArgT1, ArgT2}
  local outFoldArg::FT
  local outList::List

  (outList, outFoldArg) = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    local res::TO
    local foldArg::FT
    @match (inList1, inList2) begin
      ( nil(),  nil())  => begin
        (inAccum, inFoldArg)
      end

      (e1 <| rest1, e2 <| rest2)  => begin
        (res, foldArg) = inMapFunc(e1, e2, inArg1, inArg2, inFoldArg)
        (outList, foldArg) = threadMap2ReverseFold(rest1, rest2, inMapFunc, inArg1, inArg2, foldArg, res <| inAccum)
        (outList, foldArg)
      end
    end
  end
  (outList, outFoldArg)
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes three
extra arguments that are passed to the mapping function. =#
function threadMap3(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)  where {T1, T2, ArgT1, ArgT2, ArgT3}
  list(@do_threaded_for inMapFunc(e1, e2, inArg1, inArg2, inArg3) (e1, e2) (inList1, inList2))
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes three
extra arguments that are passed to the mapping function. =#
function threadMap3Reverse(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)  where {T1, T2, ArgT1, ArgT2, ArgT3}
  local outList::List
  listReverse(@do_threaded_for inMapFunc(e1, e2, inArg1, inArg2, inArg3) (e1, e2) (inList1, inList2))
end

#= Takes three lists and a function, and threads (interleaves) and maps the
elements of the three lists, creating a new list.
Example: thread3Map({1, 2}, {3, 4}, {5, 6}, intAdd3) => {1+3+5, 2+4+6} =#
function thread3Map(inList1::List{T1}, inList2::List{T2}, inList3::List{T3}, inFunc::MapFunc)  where {T1, T2, T3}
  list(@do_threaded_for inFunc(e1, e2, e3) (e1, e2, e3) (inList1, inList2, inList3))
end

#= Takes two lists and a function and threads (interleaves) and maps the
elements of two lists, creating a new list. This function also takes three
extra arguments and a fold argument that are passed to the mapping function.
The order of the result list will be reversed compared to the input lists. =#
function threadMap3ReverseFold(inList1::List{T1}, inList2::List{T2}, inMapFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inFoldArg::FT, inAccum::List = nil)  where {T1, T2, FT, ArgT1, ArgT2, ArgT3}
  local outFoldArg::FT
  local outList::List

  (outList, outFoldArg) = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    local res::TO
    local foldArg::FT
    @match (inList1, inList2) begin
      (e1 <| rest1, e2 <| rest2)  => begin
        (res, foldArg) = inMapFunc(e1, e2, inArg1, inArg2, inArg3, inFoldArg)
        (outList, foldArg) = threadMap3ReverseFold(rest1, rest2, inMapFunc, inArg1, inArg2, inArg3, foldArg, res <| inAccum)
        (outList, foldArg)
      end

      ( nil(),  nil())  => begin
        (inAccum, inFoldArg)
      end
    end
  end
  (outList, outFoldArg)
end

#= Takes three lists and a function, and threads (interleaves) and maps the
elements of the three lists, creating two new list.
Example: thread3Map({1, 2}, {3, 4}, {5, 6}, intAddSub3) =>
({1+3+5, 2+4+6}, {1-3-5, 2-4-6}) =#
function thread3Map_2(inList1::List{T1}, inList2::List{T2}, inList3::List{T3}, inFunc::MapFunc)  where {T1, T2, T3}
  local outList2::List = nil
  local outList1::List = nil

  local e2::T2
  local rest_e2::List{T2} = inList2
  local e3::T3
  local rest_e3::List{T3} = inList3
  local res1
  local res2

  for e1 in inList1
    @match e2 <| rest_e2 = rest_e2
    @match e3 <| rest_e3 = rest_e3
    (res1, res2) = inFunc(e1, e2, e3)
    outList1 = res1 <| outList1
    outList2 = res2 <| outList2
  end
  @match true = listEmpty(rest_e2)
  @match true = listEmpty(rest_e3)
  outList1 = listReverseInPlace(outList1)
  outList2 = listReverseInPlace(outList2)
  (outList1, outList2)
end

#= Takes three lists and a function, and threads (interleaves) and maps the
elements of the three lists, creating a new list. This function also takes
one extra argument which are passed to the mapping function and fold. =#
function thread3MapFold(inList1::List{T1}, inList2::List{T2}, inList3::List{T3}, inFunc::MapFunc, inArg::ArgT1)  where {T1, T2, T3, ArgT1}
  local outArg::ArgT1 = inArg
  local outList::List = nil

  local e2::T2
  local rest_e2::List{T2} = inList2
  local e3::T3
  local rest_e3::List{T3} = inList3
  local res

  for e1 in inList1
    @match e2 <| rest_e2 = rest_e2
    @match e3 <| rest_e3 = rest_e3
    (res, outArg) = inFunc(e1, e2, e3, outArg)
    outList = res <| outList
  end
  @match true = listEmpty(rest_e2)
  @match true = listEmpty(rest_e3)
  outList = listReverseInPlace(outList)
  (outList, outArg)
end

#= Takes three lists and a function, and threads (interleaves) and maps the
elements of the three lists, creating a new list. This function also takes
three extra arguments which are passed to the mapping function. =#
function thread3Map3(inList1::List{T1}, inList2::List{T2}, inList3::List{T3}, inFunc::MapFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)  where {T1, T2, T3, ArgT1, ArgT2, ArgT3}
  local outList::List

  outList = list(@do_threaded_for inFunc(e1, e2, e3, inArg1, inArg2, inArg3) (e1, e2, e3) (inList1, inList2, inList3))
  outList
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. This
function also takes an extra constant argument that is passed to the function. =#
function threadFold1(inList1::List{T1}, inList2::List{T2}, inFoldFunc::FoldFunc, inArg1::ArgT1, inFoldArg::FT)  where {T1, T2, FT, ArgT1}
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    local res::FT
    @match (inList1, inList2) begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inArg1, inFoldArg)
        threadFold1(rest1, rest2, inFoldFunc, inArg1, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. This
function also takes two extra constant arguments that is passed to the function. =#
function threadFold2(inList1::List{T1}, inList2::List{T2}, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inFoldArg::FT)  where {T1, T2, FT, ArgT1, ArgT2}
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    local res::FT
    @match (inList1, inList2) begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inArg1, inArg2, inFoldArg)
        threadFold2(rest1, rest2, inFoldFunc, inArg1, inArg2, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. This
function also takes three extra constant arguments that is passed to the function. =#
function threadFold3(inList1::List{T1}, inList2::List{T2}, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inFoldArg::FT)  where {T1, T2, FT, ArgT1, ArgT2, ArgT3}
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    local res::FT
    @match (inList1, inList2) begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inArg1, inArg2, inArg3, inFoldArg)
        threadFold3(rest1, rest2, inFoldFunc, inArg1, inArg2, inArg3, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. This
function also takes four extra constant arguments that is passed to the function. =#
function threadFold4(inList1::List{T1}, inList2::List{T2}, inFoldFunc::FoldFunc, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3, inArg4::ArgT4, inFoldArg::FT)  where {T1, T2, FT, ArgT1, ArgT2, ArgT3, ArgT4}
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    local res::FT
    @match (inList1, inList2) begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inArg1, inArg2, inArg3, inArg4, inFoldArg)
        threadFold4(rest1, rest2, inFoldFunc, inArg1, inArg2, inArg3, inArg4, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= This is a combination of thread and fold that applies a function to the head
of two lists with an extra argument that is updated and passed on. =#
function threadFold(inList1::List{T1}, inList2::List{T2}, inFoldFunc::FoldFunc, inFoldArg::FT)  where {T1, T2, FT}
  local outFoldArg::FT

  outFoldArg = begin
    local e1::T1
    local rest1::List{T1}
    local e2::T2
    local rest2::List{T2}
    local res::FT
    @match (inList1, inList2) begin
      (e1 <| rest1, e2 <| rest2)  => begin
        res = inFoldFunc(e1, e2, inFoldArg)
        threadFold(rest1, rest2, inFoldFunc, res)
      end

      ( nil(),  nil())  => begin
        inFoldArg
      end
    end
  end
  outFoldArg
end

#= Takes a list, an extra argument and a function. The function will be applied
to each element in the list, and the extra argument will be passed to the
function and updated. =#
function threadMapFold(inList1::List{T1}, inList2::List{T2}, inFunc::FuncType, inArg::FT)  where {T1, T2, FT}
  local outArg::FT = inArg
  local outList::List = nil

  local e2::T2
  local rest_e2::List{T2} = inList2
  local res

  for e1 in inList1
    @match e2 <| rest_e2 = rest_e2
    (res, outArg) = inFunc(e1, e2, outArg)
    outList = res <| outList
  end
  @match true = listEmpty(rest_e2)
  outList = listReverseInPlace(outList)
  (outList, outArg)
end

#= Takes a value and a list, and returns the position of the first list element
that whose value is equal to the given value.
Example: position(2, {0, 1, 2, 3}) => 3 =#
function position(inElement::T, inList::List{T})  where {T}
  local outPosition::ModelicaInteger = 1 #= one-based index =#

  for e in inList
    if valueEq(e, inElement)
      return outPosition #= one-based index =#
    end
    outPosition = outPosition + 1
  end
  fail()
  outPosition #= one-based index =#
end

#= Takes a list and a predicate function, and returns the index of the first
element for which the function returns true, or -1 if no match is found. =#
function positionOnTrue(inList::List{T}, inPredFunc::PredFunc)  where {T}
  local outPosition::ModelicaInteger = 1

  for e in inList
    if inPredFunc(e)
      return outPosition
    end
    outPosition = outPosition + 1
  end
  outPosition = -1
  outPosition
end

#= Takes a list, a predicate function and an extra argument, and return the
index of the first element for which the function returns true, or -1 if no
match is found. The extra argument is passed to the predicate function for
each call. =#
function position1OnTrue(inList::List{T}, inPredFunc::PredFunc, inArg::ArgT)  where {T, ArgT}
  local outPosition::ModelicaInteger = 1

  for e in inList
    if inPredFunc(e, inArg)
      return outPosition
    end
    outPosition = outPosition + 1
  end
  outPosition = -1
  outPosition
end

#= Takes a value and a list of lists, and returns the position of the value.
outListIndex is the index of the list the value was found in, and outPosition
is the position in that list.
Example: positionList(3, {{4, 2}, {6, 4, 3, 1}}) => (2, 3) =#
function positionList(inElement::T, inList::List{List{T}})  where {T}
  local outPosition::ModelicaInteger #= one-based index =#
  local outListIndex::ModelicaInteger = 1 #= one-based index =#

  for lst in inList
    outPosition = 1
    for e in lst
      if valueEq(e, inElement)
        return (outListIndex #= one-based index =#, outPosition #= one-based index =#)
      end
      outPosition = outPosition + 1
    end
    outListIndex = outListIndex + 1
  end
  fail()
  (outListIndex #= one-based index =#, outPosition #= one-based index =#)
end

#= Takes a value and a list, and returns the value if it's present in the list.
If not present the function will fail.
Example: listGetMember(0, {1, 2, 3}) => fail
listGetMember(1, {1, 2, 3}) => 1 =#
function getMember(inElement::T, inList::List{T})  where {T}
  local outElement::T

  local e::T
  local res::T
  local rest::List{T}

  for e in inList
    if valueEq(inElement, e)
      outElement = e
      return outElement
    end
  end
  fail()
  outElement
end

#= Takes a value and a list of values and a comparison function over two values.
If the value is present in the list (using the comparison function returning
true) the value is returned, otherwise the function fails.
Example:
function equalLength(string,string) returns true if the strings are of same length
getMemberOnTrue(\\\"a\\\",{\\\"bb\\\",\\\"b\\\",\\\"ccc\\\"},equalLength) => \\\"b\\\" =#
function getMemberOnTrue(inValue::VT, inList::List{T}, inCompFunc::CompFunc)  where {T, VT}
  local outElement::T

  for e in inList
    if inCompFunc(inValue, e)
      outElement = e
      return outElement
    end
  end
  fail()
  outElement
end

#= Returns true if a list does not contain the given element, otherwise false. =#
function notMember(inElement::T, inList::List{T})  where {T}
  local outIsNotMember::Bool

  outIsNotMember = ! listMember(inElement, inList)
  outIsNotMember
end

#= Returns true if the given value is a member of the list, as determined by the
comparison function given. =#
function isMemberOnTrue(inValue::VT, inList::List{T}, inCompFunc::CompFunc)  where {T, VT}
  local outIsMember::Bool

  for e in inList
    if inCompFunc(inValue, e)
      outIsMember = true
      return outIsMember
    end
  end
  outIsMember = false
  outIsMember
end

#= Returns true if a certain element exists in the given list as indicated by
the given predicate function.
Example:
exist({1,2}, isEven) => true
exist({1,3,5,7}, isEven) => false =#
function exist(inList::List{T}, inFindFunc::FindFunc)  where {T}
  local outExists::Bool

  for e in inList
    if inFindFunc(e)
      outExists = true
      return outExists
    end
  end
  outExists = false
  outExists
end

#= Returns true if a certain element exists in the given list as indicated by
the given predicate function. Also takes an extra argument that is passed to
the predicate function. =#
function exist1(inList::List{T}, inFindFunc::FindFunc, inExtraArg::ArgT1)  where {T, ArgT1}
  local outExists::Bool

  for e in inList
    if inFindFunc(e, inExtraArg)
      outExists = true
      return outExists
    end
  end
  outExists = false
  outExists
end

#= Returns true if a certain element exists in the given list as indicated by
the given predicate function. Also takes two extra arguments that is passed
to the predicate function. =#
function exist2(inList::List{T}, inFindFunc::FindFunc, inExtraArg1::ArgT1, inExtraArg2::ArgT2)  where {T, ArgT1, ArgT2}
  local outExists::Bool

  for e in inList
    if inFindFunc(e, inExtraArg1, inExtraArg2)
      outExists = true
      return outExists
    end
  end
  outExists = false
  outExists
end

#= Takes a list of values and a filter function over the values and returns
two lists. One of values for which the matching function returns true and the
other containing the remaining elements.
Example:
extractOnTrue({1, 2, 3, 4, 5}, isEven) => {2, 4}, {1, 3, 5} =#
function extractOnTrue(inList::List{T}, inFilterFunc::FilterFunc)  where {T}
  local outRemainingList::List{T} = nil
  local outExtractedList::List{T} = nil

  for e in inList
    if inFilterFunc(e)
      outExtractedList = e <| outExtractedList
    else
      outRemainingList = e <| outRemainingList
    end
  end
  outExtractedList = listReverseInPlace(outExtractedList)
  outRemainingList = listReverseInPlace(outRemainingList)
  (outExtractedList, outRemainingList)
end

#= Takes a list of values and a filter function over the values and an extra
argument and returns two lists. One of values for which the matching function
returns true and the other containing the remaining elements. =#
function extract1OnTrue(inList::List{T}, inFilterFunc::FilterFunc, inArg::ArgT1)  where {T, ArgT1}
  local outRemainingList::List{T} = nil
  local outExtractedList::List{T} = nil

  for e in inList
    if inFilterFunc(e, inArg)
      outExtractedList = e <| outExtractedList
    else
      outRemainingList = e <| outRemainingList
    end
  end
  outExtractedList = listReverseInPlace(outExtractedList)
  outRemainingList = listReverseInPlace(outRemainingList)
  (outExtractedList, outRemainingList)
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function succeeds.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {2, 4} =#
function filter(inList::List{T}, inFilterFunc::FilterFunc)  where {T}
  local outList::List{T} = nil

  for e in inList
    try
      inFilterFunc(e)
      outList = e <| outList
    catch
    end
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Applies a function to each element in the given list, but also filters out
all elements for which the function fails. =#
function filterMap(inList::List{TI}, inFunction::Function)  where {TI}
  local outList::List = nil
  local oe
  for e in inList
    try
      oe = inFunction(e)
      outList = oe <| outList
    catch
    end
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Applies a function to each element in the given list, but also filters out
all elements for which the function fails. =#
function filterMap1(inList::List{TI}, inFunction::Function, inExtraArg::ArgT1)  where {TI, ArgT1}
  local outList::List = nil
  local oe
  for e in inList
    try
      oe = inFunction(e, inExtraArg)
      outList = oe <| outList
    catch
    end
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {2, 4} =#
function filterOnTrue(inList::List{T}, inFilterFunc::FilterFunc)  where {T}
  list(e for e in inList if inFilterFunc(e))
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns false.
Example:
filterOnFalse({1, 2, 3, 1, 5}, isEven) => {1, 3, 1, 5} =#
function filterOnFalse(inList::List{T}, inFilterFunc::FilterFunc)  where {T}
  list(e for e in inList if boolNot(inFilterFunc(e)))
end

#= like filterOnTrue but performs the same filtering synchronously on a second list.
Takes 2 list of values and a filter function and an extra argument over the values of the first list and returns a
sub list of values for both lists for which the matching function returns true for the first list.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {2, 4} =#
function filter1OnTrueSync(inList::List{T1}, inFilterFunc::FilterFunc, inArg1::ArgT1, inSyncList::List{T2})  where {T1, T2, ArgT1}
  local outList_b::List{T2} = nil
  local outList_a::List{T1} = nil
  local e2::T2
  local rest2::List{T2} = inSyncList
  for e1 in inList
    @match e2 <| rest2 = rest2
    if inFilterFunc(e1, inArg1)
      outList_a = e1 <| outList_a
      outList_b = e2 <| outList_b
    end
  end
  outList_a = listReverseInPlace(outList_a)
  outList_b = listReverseInPlace(outList_b)
  (outList_a, outList_b)
end

#= Like filterOnTrue but performs the same filtering synchronously on a second list.
Takes 2 list of values and a filter function over the values of the first
list and returns a sub list of values for both lists for which the matching
function returns true for the first list. =#
function filterOnTrueSync(inList::List{T1}, inFilterFunc::FilterFunc, inSyncList::List{T2})  where {T1, T2}
  local outList_b::List{T2} = nil
  local outList_a::List{T1} = nil
  local e2::T2
  local rest2::List{T2} = inSyncList
  @match true = listLength(inList) == listLength(inSyncList)
  for e1 in inList
    @match e2 <| rest2 = rest2
    if inFilterFunc(e1)
      outList_a = e1 <| outList_a
      outList_b = e2 <| outList_b
    end
  end
  outList_a = listReverseInPlace(outList_a)
  outList_b = listReverseInPlace(outList_b)
  (outList_a, outList_b)
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values in reverse order for which the matching function returns true.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {4, 2} =#
function filterOnTrueReverse(inList::List{T}, inFilterFunc::FilterFunc)  where {T}
  local outList::List{T}
  listReverse(e for e in inList if inFilterFunc(e))
end

#= Takes a list of values, a filter function over the values and an extra
argument, and returns a sub list of values for which the matching function
succeeds.
Example:
filter({1, 2, 3, 4, 5}, isEven) => {2, 4} =#
function filter1(inList::List{T}, inFilterFunc::FilterFunc, inArg1::ArgT1)  where {T, ArgT1}
  local outList::List{T} = nil

  for e in inList
    try
      inFilterFunc(e, inArg1)
      outList = e <| outList
    catch
    end
  end
  outList = listReverseInPlace(outList)
  outList
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true.
Example:
filter1OnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1} =#
function filter1OnTrue(inList::List{T}, inFilterFunc::FilterFunc, inArg1::ArgT1)  where {T, ArgT1}
  list(e for e in inList if inFilterFunc(e, inArg1))
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true. The
matching function may update the values.
Example:
filter1OnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1} =#
function filter1OnTrueAndUpdate(inList::List{T}, inFilterFunc::FilterFunc, inUpdateFunc::UpdateFunc, inArg1::ArgT1)  where {T, ArgT1}
  list(inUpdateFunc(e, inArg1) for e in inList if inFilterFunc(e, inArg1))
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true.
Example:
filter1rOnTrue({1, 2, 3, 1, 5}, intEq, 1) => {1, 1} =#
function filter1rOnTrue(inList::List{T}, inFilterFunc::FilterFunc, inArg1::ArgT1)  where {T, ArgT1}
  list(e for e in inList if inFilterFunc(inArg1, e))
end

#= Takes a list of values and a filter function over the values and returns a
sub list of values for which the matching function returns true. =#
function filter2OnTrue(inList::List{T}, inFilterFunc::FilterFunc, inArg1::ArgT1, inArg2::ArgT2)  where {T, ArgT1, ArgT2}
  local outList::List{T}

  outList = list(e for e in inList if inFilterFunc(e, inArg1, inArg2))
  outList
end

#= Goes through a list and removes all elements which are equal to the given
value, using the given comparison function. =#
function removeOnTrue(inValue::VT, inCompFunc::CompFunc, inList::List{T})  where {T, VT}
  list(e for e in inList if ! inCompFunc(inValue, e))
end


select = filterOnTrue;

select1 = filter1OnTrue

select1r = filter1rOnTrue

select2 = filter2OnTrue

#= This function retrieves the first element of a list for which the passed
function evaluates to true. =#
function find(inList::List{T}, inFunc::SelectFunc)  where {T}
  local outElement::T

  for e in inList
    if inFunc(e)
      outElement = e
      return outElement
    end
  end
  fail()
  outElement
end

#= This function retrieves the first element of a list for which the passed
function evaluates to true. =#
function find1(inList::List{T}, inFunc::SelectFunc, arg1::ArgT1)  where {T, ArgT1}
  local outElement::T

  for e in inList
    if inFunc(e, arg1)
      outElement = e
      return outElement
    end
  end
  fail()
  outElement
end

#= This function retrieves the first element of a list for which the passed
function evaluates to true. And returns the list with the element removed. =#
function findAndRemove(inList::List{T}, inFunc::SelectFunc)  where {T}
  #=TODO=#
end

#= This function retrieves the first element of a list for which the passed
function evaluates to true. And returns the list with the element removed. =#
function findAndRemove1(inList::List{T}, inFunc::SelectFunc, arg1::ArgT1)  where {T, ArgT1}
  #=TODO=#
end

#= This function returns the first value in the given list for which the
corresponding element in the boolean list is true. =#
function findBoolList(inBooleans::List{Bool}, inList::List{T}, inFalseValue::T)  where {T}
  local outElement::T

  local e::T
  local rest::List{T} = inList

  for b in inBooleans
    @match e <| rest = rest
    if b
      outElement = e
      return outElement
    end
  end
  outElement = inFalseValue
  outElement
end

#= Takes a list and a value, and deletes the first occurence of the value in the
list. Example: deleteMember({1, 2, 3, 2}, 2) => {1, 3, 2} =#
function deleteMember(inList::List{T}, inElement::T)  where {T}
  local outList::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest)
    @match e <| rest = rest
    if valueEq(e, inElement)
      outList = append_reverse(outList, rest)
      return outList
    end
    outList = e <| outList
  end
  outList = inList
  outList
end

#= Same as deleteMember, but fails if the element isn't present in the list. =#
function deleteMemberF(inList::List{T}, inElement::T)  where {T}
  local outList::List{T}

  outList = deleteMember(inList, inElement)
  if referenceEq(outList, inList)
    fail()
  end
  outList
end

#= Takes a list and a value and a comparison function and deletes the first
occurence of the value in the list for which the function returns true. It
returns the new list and the deleted element, or only the original list if
no element was removed.
Example: deleteMemberOnTrue({1,2,3,2},2,intEq) => {1,3,2} =#
function deleteMemberOnTrue(inValue::VT, inList::List{T}, inCompareFunc::CompareFunc)  where {T, VT}
  local outDeletedElement::Option{T} = NONE()
  local outList::List{T} = inList

  local e::T
  local rest::List{T} = inList
  local acc::List{T} = nil

  while ! listEmpty(rest)
    @match e <| rest = rest
    if inCompareFunc(inValue, e)
      outList = append_reverse(acc, rest)
      outDeletedElement = SOME(e)
      return (outList, outDeletedElement)
    end
    acc = e <| acc
  end
  (outList, outDeletedElement)
end

#= Takes a list and a list of positions, and deletes the positions from the
list. Note that positions are indexed from 0.
Example: deletePositions({1, 2, 3, 4, 5}, {2, 0, 3}) => {2, 5} =#
function deletePositions(inList::List{T}, inPositions::List{ModelicaInteger})  where {T}
  local outList::List{T}

  local sorted_pos::List{ModelicaInteger}

  sorted_pos = sortedUnique(sort(inPositions, intGt), intEq)
  outList = deletePositionsSorted(inList, sorted_pos)
  outList
end

#= Takes a list and a sorted list of positions (smallest index first), and
deletes the positions from the list. Note that positions are indexed from 0.
Example: deletePositionsSorted({1, 2, 3, 4, 5}, {0, 2, 3}) => {2, 5} =#
function deletePositionsSorted(inList::List{T}, inPositions::List{ModelicaInteger})  where {T}
  local outList::List{T} = nil

  local i::ModelicaInteger = 0
  local e::T
  local rest::List{T} = inList

  for pos in inPositions
    while i != pos
      @match e <| rest = rest
      outList = e <| outList
      i = i + 1
    end
    @match _ <| rest = rest
    i = i + 1
  end
  outList = append_reverse(outList, rest)
  outList
end

#= Removes all matching integers that occur first in a list. If the first
element doesn't match it returns the list. =#
function removeMatchesFirst(inList::List{<:ModelicaInteger}, inN::ModelicaInteger) ::List{ModelicaInteger}
  local outList::List{ModelicaInteger} = inList

  for e in inList
    if e != inN
      break
    end
    @match _ <| outList = outList
  end
  outList
end

#= Takes an element, a position and a list, and replaces the value at the given
position in the list. Position is an integer between 1 and n for a list of
n elements.
Example: replaceAt('A', 2, {'a', 'b', 'c'}) => {'a', 'A', 'c'} =#
function replaceAt(inElement::T, inPosition::ModelicaInteger #= one-based index =#, inList::List{T})  where {T}
  #==#
  println("Todo")
end

#= Applies the function to each element of the list until the function returns
true, and then replaces that element with the replacement.
Example: replaceOnTrue(4, {1, 2, 3}, isTwo) => {1, 4, 3}. =#
function replaceOnTrue(inReplacement::T, inList::List{T}, inFunc::FuncType)  where {T}
  local outReplaced::Bool = false
  local outList::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest)
    @match e <| rest = rest
    if inFunc(e)
      outReplaced = true
      outList = append_reverse(outList, inReplacement <| rest)
      return (outList, outReplaced)
    end
    outList = e <| outList
  end
  outList = inList
  (outList, outReplaced)
end

#= Takes an element, a position and a list, and replaces the value at the given
position in the list. Position is an integer between 1 and n for a list of
n elements.
Example: replaceAtIndexFirst(2, 'A', {'a', 'b', 'c'}) => {'a', 'A', 'c'} =#
function replaceAtIndexFirst(inPosition::ModelicaInteger #= one-based index =#, inElement::T, inList::List{T})  where {T}
  local outList::List{T}

  outList = replaceAt(inElement, inPosition, inList)
  outList
end

#= Takes an list, a position and a list, and replaces the element at the given
position with the first list in the second list. Position is an integer
between 0 and n - 1 for a list of n elements.
Example: replaceAt({'A', 'B'}, 1, {'a', 'b', 'c'}) => {'a', 'A', 'B', 'c'} =#
function replaceAtWithList(inReplacementList::List{T}, inPosition::ModelicaInteger, inList::List{T})  where {T}
  local outList::List{T} = nil

  local e::T
  local rest::List{T} = inList

  @match true = inPosition >= 0
  #=  Shuffle elements from inList to outList until the position is reached.
  =#
  for i in 0:inPosition - 1
    @match e <| rest = rest
    outList = e <| outList
  end
  #=  Replace the element at the position and append the remaining elements.
  =#
  @match _ <| rest = rest
  rest = listAppend(inReplacementList, rest)
  outList = append_reverse(outList, rest)
  outList
end

#= Takes
- an element,
- a position (indexed from 1)
- a list and
- a fill value
The function replaces the value at the given position in the list, if the
given position is out of range, the fill value is used to padd the list up to
that element position and then insert the value at the position
Example: replaceAtWithFill(\\\"A\\\", 5, {\\\"a\\\",\\\"b\\\",\\\"c\\\"},\\\"dummy\\\") =>
{\\\"a\\\",\\\"b\\\",\\\"c\\\",\\\"dummy\\\",\\\"A\\\"} =#
function replaceAtWithFill(inElement::T, inPosition::ModelicaInteger, inList::List{T}, inFillValue::T)  where {T}
  local outList::List{T}

  local len::ModelicaInteger
  local fill_lst::List{T}

  @match true = inPosition >= 0
  len = listLength(inList)
  if inPosition <= len
    outList = replaceAt(inElement, inPosition, inList)
  else
    fill_lst = list(inElement)
    for i in 2:inPosition - len
      fill_lst = inFillValue <| fill_lst
    end
    outList = listAppend(inList, fill_lst)
  end
  outList
end

#= Creates a string from a list and a function that maps a list element to a
string. It also takes several parameters that determine the formatting of
the string. Ex:
toString({1, 2, 3}, intString, 'nums', '{', ';', '}, true) =>
'nums{1;2;3}'
=#
function toString(inList::List{T}, inPrintFunc::FuncType, inListNameStr::String #= The name of the list. =#, inBeginStr::String #= The start of the list =#, inDelimitStr::String #= The delimiter between list elements. =#, inEndStr::String #= The end of the list. =#, inPrintEmpty::Bool #= If false, don't output begin and end if the list is empty. =#)  where {T}
  local outString::String

  outString = begin
    local str::String
    #=  Empty list and inPrintEmpty true => concatenate the list name, begin
    =#
    #=  string and end string.
    =#
    @match (inList, inPrintEmpty) begin
      ( nil(), true)  => begin
        stringAppendList(list(inListNameStr, inBeginStr, inEndStr))
      end

      ( nil(), false)  => begin
        inListNameStr
      end

      _  => begin
        str = stringDelimitList(map(inList, inPrintFunc), inDelimitStr)
        str = stringAppendList(list(inListNameStr, inBeginStr, str, inEndStr))
        str
      end
    end
  end
  #=  Empty list and inPrintEmpty false => output only list name.
  =#
  outString
end

#= @author:adrpo
returns true if the list has exactly one element, otherwise false =#
function hasOneElement(inList::List{T})  where {T}
  local b::Bool

  b = begin
    @match inList begin
      _ <|  nil()  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  b
end

#= author:waurich
returns true if the list has more than one element, otherwise false =#
function hasSeveralElements(inList::List{T})  where {T}
  local b::Bool

  b = begin
    @match inList begin
      _ <|  nil()  => begin
        false
      end

      nil()  => begin
        false
      end

      _  => begin
        true
      end
    end
  end
  b
end

function lengthListElements(inListList::List{List{T}})  where {T}
  local outLength::ModelicaInteger

  outLength = sum(listLength(lst) for lst in inListList)
  outLength
end

#= This function generates a list by calling the given function with the given
argument. The elements generated by the function are accumulated in a list
until the function returns false as the last return value. =#
function generate(inArg::ArgT1, inFunc::GenerateFunc)  where {T, ArgT1}
  local outList::List{T}

  outList = listReverseInPlace(generateReverse(inArg, inFunc))
  outList
end

#= This function generates a list by calling the given function with the given
argument. The elements generated by the function are accumulated in a list
until the function returns false as the last return value. This function
returns the generated list reversed. =#
function generateReverse(inArg::ArgT1, inFunc::GenerateFunc)  where {T, ArgT1}
  local outList::List{T} = nil

  local cont::Bool
  local arg::ArgT1 = inArg
  local e::T

  while true
    (arg, e, cont) = inFunc(arg)
    if ! cont
      break
    end
    outList = e <| outList
  end
  outList
end

#= Like mapFold, but with the function split into a map and a fold function. =#
function mapFoldSplit(inList::List{TI}, inMapFunc::MapFunc, inFoldFunc::FoldFunc, inStartValue::FT)  where {TI, FT}
  local outResult::FT = inStartValue
  local outList::List = nil

  local eo
  local res::FT

  for e in inList
    (eo, res) = inMapFunc(e)
    outResult = inFoldFunc(res, outResult)
    outList = eo <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, outResult)
end

#= Like map1Fold, but with the function split into a map and a fold function. =#
function map1FoldSplit(inList::List{TI}, inMapFunc::MapFunc, inFoldFunc::FoldFunc, inConstArg::ArgT1, inStartValue::FT)  where {TI, FT, ArgT1}
  local outResult::FT = inStartValue
  local outList::List = nil

  local eo
  local res::FT

  for e in inList
    (eo, res) = inMapFunc(e, inConstArg)
    outResult = inFoldFunc(res, outResult)
    outList = eo <| outList
  end
  outList = listReverseInPlace(outList)
  (outList, outResult)
end


#= Takes a list and a function. The function is applied to each element in the
list, and the function is itself responsible for adding elements to the
result list. =#
function accumulateMapReverse(inList::List{TI}, inMapFunc::MapFunc)  where {TI}
  local outList::List = nil

  for e in inList
    outList = inMapFunc(e, outList)
  end
  outList
end

#= Takes a list, a function and a result list. The function is applied to each
element of the list, and the function is itself responsible for adding
elements to the result list. =#
function accumulateMapAccum(inList::List{TI}, inMapFunc::MapFunc)  where {TI}
  local outList::List = nil

  for e in inList
    outList = inMapFunc(e, outList)
  end
  outList = listReverse(outList)
  outList
end

accumulateMap = accumulateMapAccum

#= Takes a list, a function, an extra argument, and a result list. The function
is applied to each element of the list, and the function is itself responsible
for adding elements to the result list. =#
function accumulateMapAccum1(inList::List{TI}, inMapFunc::MapFunc, inArg::ArgT1)  where {TI, ArgT1}
  local outList::List = nil

  for e in inList
    outList = inMapFunc(e, inArg, outList)
  end
  outList = listReverse(outList)
  outList
end


function accumulateMapFoldAccum(inList::List{TI}, inFunc::FuncType, inFoldArg::FT)  where {TI, FT}
  local outFoldArg::FT = inFoldArg
  local outList::List = nil

  for e in inList
    (outList, outFoldArg) = inFunc(e, outFoldArg, outList)
  end
  outList = listReverse(outList)
  (outList, outFoldArg)
end

accumulateMapFold = accumulateMapFoldAccum

function first2FromTuple3(inTuple::Tuple{T, T, T})  where {T}
  local outList::List{T}

  local a::T
  local b::T

  (a, b, _) = inTuple
  outList = list(a, b)
  outList
end

#= Same as map, but stops when it find a certain element as indicated by the
mapping function. Returns the new list, and whether the element was found or
not. =#
function findMap(inList::List{T}, inFunc::FuncType)  where {T}
  local outFound::Bool = false
  local outList::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest) && ! outFound
    @match e <| rest = rest
    (e, outFound) = inFunc(e)
    outList = e <| outList
  end
  outList = append_reverse(outList, rest)
  (outList, outFound)
end

#= Same as map1, but stops when it find a certain element as indicated by the
mapping function. Returns the new list, and whether the element was found or
not. =#
function findMap1(inList::List{T}, inFunc::FuncType, inArg1::ArgT1)  where {T, ArgT1}
  local outFound::Bool = false
  local outList::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest) && ! outFound
    @match e <| rest = rest
    (e, outFound) = inFunc(e, inArg1)
    outList = e <| outList
  end
  outList = append_reverse(outList, rest)
  (outList, outFound)
end

#= Same as map2, but stops when it find a certain element as indicated by the
mapping function. Returns the new list, and whether the element was found or
not. =#
function findMap2(inList::List{T}, inFunc::FuncType, inArg1::ArgT1, inArg2::ArgT2)  where {T, ArgT1, ArgT2}
  local outFound::Bool = false
  local outList::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest) && ! outFound
    @match e <| rest = rest
    (e, outFound) = inFunc(e, inArg1, inArg2)
    outList = e <| outList
  end
  outList = append_reverse(outList, rest)
  (outList, outFound)
end

#= Same as map3, but stops when it find a certain element as indicated by the
mapping function. Returns the new list, and whether the element was found or
not. =#
function findMap3(inList::List{T}, inFunc::FuncType, inArg1::ArgT1, inArg2::ArgT2, inArg3::ArgT3)  where {T, ArgT1, ArgT2, ArgT3}
  local outFound::Bool = false
  local outList::List{T} = nil

  local e::T
  local rest::List{T} = inList

  while ! listEmpty(rest) && ! outFound
    @match e <| rest = rest
    (e, outFound) = inFunc(e, inArg1, inArg2, inArg3)
    outList = e <| outList
  end
  outList = append_reverse(outList, rest)
  (outList, outFound)
end

#= Applies the given function over the list and returns first returned value that is not NONE(). =#
function findSome(inList::List{T1}, inFunc::FuncType)  where {T1, T2}
  local outVal::T2

  local retOpt::Option{T2} = NONE()
  local e::T1
  local rest::List{T1} = inList

  while isNone(retOpt)
    @match e <| rest = rest
    retOpt = inFunc(e)
  end
  #= /*not listEmpty(rest) and not outFound*/ =#
  outVal = begin
    @match retOpt begin
      SOME(outVal)  => begin
        outVal
      end
    end
  end
  outVal
end

#= Applies the given function with one extra argument over the list and returns first returned value that is not NONE(). =#
function findSome1(inList::List{T1}, inFunc::FuncType, inArg::Arg)  where {T1, T2, Arg}
  local outVal::T2

  local retOpt::Option{T2} = NONE()
  local e::T1
  local rest::List{T1} = inList

  while isNone(retOpt)
    @match e <| rest = rest
    retOpt = inFunc(e, inArg)
  end
  #= /*not listEmpty(rest) and not outFound*/ =#
  outVal = begin
    @match retOpt begin
      SOME(outVal)  => begin
        outVal
      end
    end
  end
  outVal
end

function splitEqualPrefix(inFullList::List{T1}, inPrefixList::List{T2}, inEqFunc::EqFunc, inAccum::List{T1} = nil)  where {T1, T2}
  local outRest::List{T1}
  local outPrefix::List{T1} = nil

  local e1::T1
  local e2::T2
  local rest_e1::List{T1} = inFullList
  local rest_e2::List{T2} = inPrefixList

  while true
    if listEmpty(rest_e1) || listEmpty(rest_e2)
      break
    end
    @match e1 <| rest_e1 = rest_e1
    @match e2 <| rest_e2 = rest_e2
    if ! inEqFunc(e1, e2)
      break
    end
    outPrefix = e1 <| outPrefix
  end
  outPrefix = listReverseInPlace(outPrefix)
  outRest = rest_e1
  (outPrefix, outRest)
end

#= Takes a two-dimensional list and creates a list combinations
given by the cartesian product of the sublists.

Ex: combination({{1, 2}, {3}, {4, 5}}) =>
{{1, 3, 4}, {1, 3, 5}, {2, 3, 4}, {2, 3, 5}}
=#
function combination(inElements::List{List{TI}})  where {TI}
  local outElements::List{List{TI}}

  local elems::List{List{TI}}

  if listEmpty(inElements)
    outElements = nil
  else
    elems = combination_tail(inElements, nil, nil)
    outElements = listReverse(elems)
  end
  outElements
end

function combination_tail(inElements::List{List{TI}}, inCombination::List{TI}, inAccumElems::List{List{TI}})  where {TI}
  local outElements::List{List{TI}}

  outElements = begin
    local head::List{TI}
    local rest::List{List{TI}}
    local acc::List{List{TI}}
    @match inElements begin
      head <| rest  => begin
        acc = inAccumElems
        for e in head
          acc = combination_tail(rest, e <| inCombination, acc)
        end
        acc
      end

      _  => begin
        listReverse(inCombination) <| inAccumElems
      end
    end
  end
  outElements
end

#= Takes a two-dimensional list and calls the given function on the combinations
given by the cartesian product of the sublists.

Ex: combinationMap({{1, 2}, {3}, {4, 5}}, func) =>
{func({1, 3, 4}), func({1, 3, 5}), func({2, 3, 4}), func({2, 3, 5})}
=#
function combinationMap(inElements::List{List{TI}}, inMapFunc::MapFunc)  where {TI}
  local outElements::List

  local elems::List

  elems = combinationMap_tail(inElements, inMapFunc, nil, nil)
  outElements = listReverse(elems)
  outElements
end

function combinationMap_tail(inElements::List{List{TI}}, inMapFunc::MapFunc, inCombination::List{TI}, inAccumElems::List)  where {TI}
  local outElements::List

  outElements = begin
    local head::List{TI}
    local rest::List{List{TI}}
    local acc::List
    @match inElements begin
      head <| rest  => begin
        acc = inAccumElems
        for e in head
          acc = combinationMap_tail(rest, inMapFunc, e <| inCombination, acc)
        end
        acc
      end

      _  => begin
        inMapFunc(listReverse(inCombination)) <| inAccumElems
      end
    end
  end
  outElements
end

#= Takes a two-dimensional list and calls the given function on the combinations
given by the cartesian product of the sublists. Also takes an extra constant
argument that is sent to the function.

Ex: combinationMap({{1, 2}, {3}, {4, 5}}, func, x) =>
{func({1, 3, 4}, x), func({1, 3, 5}, x), func({2, 3, 4}, x), func({2, 3, 5}, x)}
=#
function combinationMap1(inElements::List{List{TI}}, inMapFunc::MapFunc, inArg::ArgT1)  where {TI, ArgT1}
  local outElements::List

  local elems::List

  elems = combinationMap1_tail(inElements, inMapFunc, inArg, nil, nil)
  outElements = listReverse(elems)
  outElements
end

function combinationMap1_tail(inElements::List{List{TI}}, inMapFunc::MapFunc, inArg::ArgT1, inCombination::List{TI}, inAccumElems::List)  where {TI, ArgT1}
  local outElements::List

  outElements = begin
    local head::List{TI}
    local rest::List{List{TI}}
    local acc::List
    @match inElements begin
      head <| rest  => begin
        acc = inAccumElems
        for e in head
          acc = combinationMap1_tail(rest, inMapFunc, inArg, e <| inCombination, acc)
        end
        acc
      end

      _  => begin
        inMapFunc(listReverse(inCombination), inArg) <| inAccumElems
      end
    end
  end
  outElements
end

function combinationMap1_tail2(inHead::List{TI}, inRest::List{List{TI}}, inMapFunc::MapFunc, inArg::ArgT1, inCombination::List{TI}, inAccumElems::List)  where {TI, ArgT1}
  local outElements::List

  outElements = begin
    local head::TI
    local rest::List{TI}
    local comb::List{TI}
    local accum::List
    @match (inHead, inCombination, inAccumElems) begin
      (head <| rest, comb, accum)  => begin
        accum = combinationMap1_tail(inRest, inMapFunc, inArg, head <| comb, accum)
        combinationMap1_tail2(rest, inRest, inMapFunc, inArg, comb, accum)
      end

      _  => begin
        inAccumElems
      end
    end
  end
  outElements
end

#= Checks if all elements in the lists have equal references =#
function allReferenceEq(inList1::List{T}, inList2::List{T})  where {T}
  local outEqual::Bool

  outEqual = begin
    local el1::T
    local el2::T
    local rest1::List{T}
    local rest2::List{T}
    @match (inList1, inList2) begin
      (el1 <| rest1, el2 <| rest2)  => begin
        if referenceEq(el1, el2)
          allReferenceEq(rest1, rest2)
        else
          false
        end
      end

      ( nil(),  nil())  => begin
        true
      end

      _  => begin
        false
      end
    end
  end
  outEqual
end

#= Takes two lists and a comparison function and removes the heads from both
lists as long as they are equal. Ex:
removeEqualPrefix({1, 2, 3, 5, 7}, {1, 2, 3, 9, 7}) => ({5, 7}, {9, 7}) =#
function removeEqualPrefix(inList1::List{T1}, inList2::List{T2}, inCompFunc::CompFunc)  where {T1, T2}
  local outList2::List{T2} = inList2
  local outList1::List{T1} = inList1

  local e1::T1
  local e2::T2

  while ! (listEmpty(outList1) || listEmpty(outList2))
    e1 = listHead(outList1)
    e2 = listHead(outList2)
    if ! inCompFunc(e1, e2)
      break
    end
    outList1 = listRest(outList1)
    outList2 = listRest(outList2)
  end
  (outList1, outList2)
end

#= Returns true if inList1 is longer than inList2, otherwise false. =#
function listIsLonger(inList1::List{T}, inList2::List{T})  where {T}
  local isLonger::Bool

  isLonger = intGt(listLength(inList1), listLength(inList2))
  isLonger
end

function toListWithPositions(inList::List{T})  where {T}
  local outList::List{Tuple{T, ModelicaInteger}} = nil

  local pos::ModelicaInteger = 1

  for e in inList
    outList = (e, pos) <| outList
    pos = pos + 1
  end
  outList = listReverseInPlace(outList)
  outList
end

#= @author: adrpo
make NONE() if the list is empty
make SOME(list) if the list is not empty =#
function mkOption(inList::List{T})  where {T}
  local outOption::Option{List{T}}

  outOption = if listEmpty(inList)
    NONE()
  else
    SOME(inList)
  end
  outOption
end

#= Returns true if the given predicate function returns true for all elements in
the given list. =#
function all(inList::List{T}, inFunc::PredFunc)  where {T}
  local outResult::Bool

  for e in inList
    if ! inFunc(e)
      outResult = false
      return outResult
    end
  end
  outResult = true
  outResult
end

#= Takes a list of values and a filter function over the values and returns 2
sub lists of values for which the matching function returns true and false. =#
function separateOnTrue(inList::List{T}, inFilterFunc::FilterFunc)  where {T}
  local outListFalse::List{T} = nil
  local outListTrue::List{T} = nil

  for e in inList
    if inFilterFunc(e)
      outListTrue = e <| outListTrue
    else
      outListFalse = e <| outListFalse
    end
  end
  (outListTrue, outListFalse)
end

#= Takes a list of values and a filter function over the values and returns 2
sub lists of values for which the matching function returns true and false. =#
function separate1OnTrue(inList::List{T}, inFilterFunc::FilterFunc, inArg1::ArgT1)  where {T, ArgT1}
  local outListFalse::List{T} = nil
  local outListTrue::List{T} = nil

  for e in inList
    if inFilterFunc(e, inArg1)
      outListTrue = e <| outListTrue
    else
      outListFalse = e <| outListFalse
    end
  end
  (outListTrue, outListFalse)
end

function mapFirst(inList::List{TI}, inFunc::FindMapFunc)  where {TI}
  local outElement

  local found::Bool

  for e in inList
    (outElement, found) = inFunc(e)
    if found
      return outElement
    end
  end
  fail()
  outElement
end

function isSorted(inList::List{T}, inFunc::Comp)  where {T}
  local b::Bool = true

  local found::Bool
  local prev::T

  if listEmpty(inList)
    return b
  end
  @match prev <| _ = inList
  for e in listRest(inList)
    if ! inFunc(prev, e)
      b = false
      return b
    end
  end
  b
end

#= Applies a function to only the elements given by the sorted list of indices. =#
function mapIndices(inList::List{T}, indices::List{ModelicaInteger}, func::MapFunc)  where {T}
  local outList::List{T}

  local i::ModelicaInteger = 1
  local idx::ModelicaInteger
  local rest_idx::List{ModelicaInteger}
  local e::T
  local rest_lst::List{T}

  if listEmpty(indices)
    outList = inList
    return outList
  end
  @match idx <| rest_idx = indices
  rest_lst = inList
  outList = nil
  while ! listEmpty(rest_lst)
    @match e <| rest_lst = rest_lst
    if i == idx
      outList = func(e) <| outList
      if listEmpty(rest_idx)
        outList = append_reverse(rest_lst, outList)
        break
      else
        @match idx <| rest_idx = rest_idx
      end
    else
      outList = e <| outList
    end
    i = i + 1
  end
  outList = listReverseInPlace(outList)
  outList
end

#= So that we can use wildcard imports and named imports when they do occur. Not good Julia practice =#
@exportAll()
end
