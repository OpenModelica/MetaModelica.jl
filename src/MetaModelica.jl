module MetaModelica

include("list.jl")
include("matchcontinue.jl")
include("metaModelicaTypes.jl")

export @match, @matchcontinue, MatchFailure, ModelicaReal, ModelicaInteger

end
