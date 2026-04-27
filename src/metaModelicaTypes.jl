#= Internal use only. =#
module MetaModelicaTypes

#= Modelica real numbers differ from Julia real numbers. =#
const ModelicaReal = Float64
const ModelicaInteger = Int
#=
TODO:

1. Ideally, MetaModelica Real would accept Int64 inputs while returning AbstractFloat.
2. Avoid mixing ModelicaInteger and ModelicaReal.
=#

abstract type MetaModelicaException <: Exception end

export ModelicaInteger, ModelicaReal, MetaModelicaException

end
