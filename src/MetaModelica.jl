module MetaModelica

include("list.jl")
include("matchcontinue.jl")
include("metaModelicaTypes.jl")
include("union.jl")
include("functionInheritance.jl")

export @match, @matchcontinue, MatchFailure, ModelicaReal, ModelicaInteger
export @Uniontype, @Record, @UniontypeDecl, @ExtendFunction

end
