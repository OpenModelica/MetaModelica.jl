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
function arrayUpdateNoBoundsChecking(arr::Vector{A}, index::ModelicaInteger,
                                     newValue::A) where {A}
  local newArray = arr
  @inbounds newArray[index] = newValue
  return newArray
end

""" Creates a new array where the elements are *not* initialized!. Any attempt to
access an uninitialized elements may cause segmentation faults if you're
lucky, and pretty much anything else if you're not. Do not use unless you will
immediately fill the whole array with data. The dummy variable is used to fix
the type of the array. """
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

""" O(1). A destructive operation changing the \"first\" part of a cons-cell. """
function listSetFirst(inConsCell::List{A}, inNewContent::A) where {A} #= A non-empty list =#
  @error "Not listSetFirst defined in the runtime"
end

""" O(1). A destructive operation changing the rest part of a cons-cell """
#= NOTE: Make sure you do NOT create cycles as infinite lists are not handled well in the compiler. =#
function listSetRest(inConsCell::List{A}, inNewRest::List{A}) where {A} #= A non-empty list =#
  @error "Not listSetRest defined in the runtime"
end

""" O(n) """
function listArrayLiteral(lst::List{A})::Array{A} where {A}
  local arr::Array{A} = listArray(lst)
  arr
end

ExportAll.@exportAll()

end #=End dangerous =#
