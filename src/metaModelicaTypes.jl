#= !!For internal use only!! =#
module MetaModelicaTypes

#= Real numbers are a bit different in Modelica compared to Julia =#
const ModelicaReal = Float64
const ModelicaInteger = Int
#=
TODO:

#1 Ideally we would like MetaModelica Real to be defined in such a way that it
 can accept Int64, but when it returns it will return AbstractFloat

#2 Furthermore, we do not wish to mix ModelicaInteger with ModelicaReal.
   Attemped this during the 7th of July. I failed :(
=#

abstract type MetaModelicaException <: Exception end

export ModelicaInteger, ModelicaReal, MetaModelicaException

end
