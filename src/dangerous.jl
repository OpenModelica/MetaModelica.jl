#=
  The MetaModelica.Dangerous module.
  Most things here are stubs
=#

module Dangerous

import ExportAll
using ..MetaModelica

""" O(1) """
function arrayGetNoBoundsChecking(arr::Array, index::ModelicaInteger)
  @inbounds arr[index]
end

""" O(1) """
function arrayUpdateNoBoundsChecking(arr::Array{T}, index::ModelicaInteger, newValue::T) where {T}
  local newArray = arr
  if index < 0
    println("arrayUpdateNoBoundsChecking: index < 0!")
  end
  @inbounds newArray[index] = newValue
  newArray
end

""" Creates a new array where the elements are *not* initialized!. Any attempt to
access an uninitialized elements may cause segmentation faults if you're
lucky, and pretty much anything else if you're not. Do not use unless you will
immediately fill the whole array with data. The dummy variable is used to fix
the type of the array. """
function arrayCreateNoInit(size::ModelicaInteger, dummy::T) where {T}
  local arr = fill(dummy, size)
  arr
end

""" O(1) """
function stringGetNoBoundsChecking(str::String, index::ModelicaInteger)::ModelicaInteger
  local ch::ModelicaInteger
  if index < 0
    println("stringGetNoBoundsChecking: index < 0!")
  end
  ch = @inbounds str[index]
end

""" Not possible unless we write a C list impl for Julia """
function listReverseInPlace(inList::List{T}) where {T}
  MetaModelica.listReverse(inList)
end

""" O(1). A destructive operation changing the \"first\" part of a cons-cell. """
function listSetFirst(inConsCell::Cons{A}, inNewContent::A) where {A} #= A non-empty list =#
  @assign inConsCell.head = inNewConent
end

""" 
O(1). A destructive operation changing the rest part of a cons-cell 
NOTE: Make sure you do NOT create cycles as infinite lists are not handled well in the compiler. 
"""
function listSetRest(inConsCell::Cons{T}, inNewRest::List{T}) where {T} #= A non-empty list =#
  @assign inConsCell.tail = inNewRest
end

""" O(n) """
function listArrayLiteral(lst::List{T}) where {T}
  local arr = listArray(lst)
  arr
end

ExportAll.@exportAll()

end #=End dangerous =#
