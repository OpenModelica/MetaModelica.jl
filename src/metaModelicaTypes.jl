#= !!For internal use only!! =#
module MetaModelicaTypes

#= Real numbers are a bit different in Modelica compared to Julia =#
const ModelicaReal = Union{Signed, AbstractFloat}
const ModelicaInteger = Signed
#=
TODO:

#1 Ideally we would like MetaModelica Real to be defined in such a way that it
 can accept Int64, but when it returns it will return AbstractFloat

#2 Furthermore, we do not wish to mix ModelicaInteger with ModelicaReal.
   Attemped this during the 7th of July. I failed :(
=#


#=Martin was right as always. Martin is always right ignoring 100% Modelica semantics here... Not common, we can fix it if it occurs=#

export ModelicaInteger, ModelicaReal

end
