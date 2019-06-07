#= Arrays are boxed in Julia. It seems that we can just reuse the Julia arrays straight away=#
#= Addendum, the only difference seems to be that  MetaModelica arrays internally keep track on how many elements it contains=#
abstract type Array{T} <: Array end
export Array
