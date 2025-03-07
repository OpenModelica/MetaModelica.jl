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


import ImmutableList
#=Wrapper function to ImmutableList.Unsafe =#
const listArrayLiteral = ImmutableList.Unsafe.listArrayLiteral
const listGetFirstAsPtr = ImmutableList.Unsafe.listGetFirstAsPtr
const listReverseInPlace = ImmutableList.Unsafe.listReverseInPlace
const listReverseInPlace2 = ImmutableList.Unsafe.listReverseInPlace2
const listSetFirst = ImmutableList.Unsafe.listSetFirst
const listSetRest = ImmutableList.Unsafe.listSetRest

"""
  Unsafe function to get pointers from immutable struct.
  Use with !care!
"""
function unsafe_pointer_from_objref(@nospecialize(x))
  ccall(:jl_value_ptr, Ptr{Cvoid}, (Any,), x)
end


ExportAll.@exportAll()

end #=End dangerous =#
