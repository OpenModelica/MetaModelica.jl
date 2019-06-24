#= Arrays are boxed in Julia. It seems that we can just reuse the Julia arrays straight away=#
abstract type Array{T} <: Array end
export array
