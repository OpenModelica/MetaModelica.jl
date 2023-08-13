#=
  The MetaModelica.Dangerous module.
  Most things here are stubs
=#

module Dangerous

import ExportAll
using ..MetaModelica

""" O(1) """
function arrayGetNoBoundsChecking(arr::Vector{A}, index::ModelicaInteger) where {A}
  @inbounds arr[index]
end

""" O(1) """
function arrayUpdateNoBoundsChecking(arr::Vector{A},
                                     index::ModelicaInteger,
                                     newValue::A) where {A}
  local newArray = arr
  @inbounds newArray[index] = newValue
  return newArray
end

""" Creates a new array where the elements are *not* initialized!. Any attempt to
access an uninitialized elements may cause segmentation faults if you're
lucky, and pretty much anything else if you're not. Do not use unless you will
immediately fill the whole array with data. The dummy variable is used to fix
the type of the array.
"""
function arrayCreateNoInit(size::ModelicaInteger, dummy::A)::Array{A} where {A}
  local arr::Array{A} = fill(dummy, size)
  arr
end

""" O(1) """
function stringGetNoBoundsChecking(str::String, index::ModelicaInteger)
  local ch::ModelicaInteger
  ch = @inbounds str[index]
end

""" Not possible unless we write a C list impl for Julia """
function listReverseInPlace(inList::List{T})::List{T} where {T}
  MetaModelica.listReverse(inList)
end


function listReverseInPlace2(inList::Nil)
  return inList#MetaModelica.listReverse(inList)
end

"""
 Unsafe implementation of list reverse in place.
 Instead of creating new cons cells we swap pointers...
"""
function listReverseInPlace2(lst::Cons{T}) where {T}
  local prev = nil
  #= Declare an unsafe pointer to the list =#
  local oldCdrPtr::Ptr{List{T}}
  GC.@preserve while (!(lst isa Nil))
   println("prev at the iteration:")
    println(prev)
    println("lst at the iteration:")
    println(lst)
    println("before oldCdr = $(lst.tail)")
    oldCdr = deepcopy(lst.tail)
    println("Before listSetRest($lst, $prev)")
    listSetRest(lst, prev)
    println("Before prev = $lst")
    prev = lst
    println("Before lst = $(oldCdr) //oldCdr")
    lst = oldCdr
  end
  println("After loop")
  return prev
end


"""
O(1). A destructive operation changing the \"first\" part of a cons-cell.
TODO: Not implemented
"""
function listSetFirst(inConsCell::Cons{A}, inNewContent::A) where {A} #= A non-empty list =#
  firstPtr::Ptr{A} = unsafe_getListAsPtr(inConsCell)
  #local newHead = Cons{T}(inNewContent, inConsCell.tail)
  # unsafe_store!(firstPtr, inNewContent)
end

""" O(1). A destructive operation changing the rest part of a cons-cell """
#= NOTE: Make sure you do NOT create cycles as infinite lists are not handled well in the compiler. =#
function listSetRest(inConsCell::Cons{A}, inNewRest::Cons{A}) where {A} #= A non-empty list =#
  newTailPtr::Ptr{Cons{A}} = unsafe_getListAsPtr(inNewRest)
  inConsCellTailPtr::Ptr{Cons{A}} = unsafe_getListTailAsPtr(inConsCell)
  inConsCellTailPtr2::Ptr{Cons{A}} = unsafe_getListAsPtr(inConsCell)
  GC.@preserve(unsafe_store!(inConsCellTailPtr, unsafe_load(newTailPtr)))
  return inConsCell
end

"""
  We create one cons cell when the tail we are setting is a nil...
"""
function listSetRest(inConsCell::Cons{A}, inNewRest::Nil) where {A} #= A non-empty list =#
  local lstPtr::Ptr{Cons{A}} = unsafe_getListAsPtr(inConsCell)
  local val = inConsCell.head
  GC.@preserve unsafe_store!(lstPtr, Cons{A}(inConsCell.head, inNewRest))
  return inConsCell
end


""" O(n) """
function listArrayLiteral(lst::List{A})::Array{A} where {A}
  local arr::Array{A} = listArray(lst)
  arr
end

"""
```
listGetFirstAsPtr(lst::Cons{T})::Ptr{T}
```

Dangerous function.
Gets the first element of the list as a pointer of type T.
Unless it is nil then we get a NULL pointer
"""
function unsafe_getListHeadAsPtr(lst::Cons{T}) where{T}
  convert(Ptr{T}, unsafe_pointer_from_objref(lst.head))
end

"""
``` listGetFirstAsPtr(nil)::Ptr{Nothing}```
Returns a null pointer
"""
function unsafe_getListHeadAsPtr(lst::Nil)
  unsafe_pointer_from_objref(nil)
end

"""
  Fetches the pointer to the tail of the list
```
unsafe_listGetTailAsPtr{lst::List{T}}::Ptr{Cons{T}}
```
"""
function unsafe_getListTailAsPtr(lst::List{T}) where {T}
  if lst.tail === nil
    return unsafe_pointer_from_objref(nil)
  else
    convert(Ptr{Cons{T}}, unsafe_pointer_from_objref(lst.tail))
  end
end

"""
Unsafley get a pointer to a list.
"""
function unsafe_getListAsPtr(lst::List{T}) where {T}
  if lst === nil
    ptrToNil::Ptr{Nil{Any}} = unsafe_pointer_from_objref(nil)
    return ptrToNil
  else
    convert(Ptr{Cons{T}}, unsafe_pointer_from_objref(lst))
  end
end




"""
  Unsafe function to get pointers from immutable struct.
  Use with !care!
"""
function unsafe_pointer_from_objref(@nospecialize(x))
  ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
end


ExportAll.@exportAll()

end #=End dangerous =#
