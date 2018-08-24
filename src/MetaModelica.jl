module MetaModelica

include("list.jl")

include("matchcontinue.jl")
export @match, @matchcontinue, MatchFailure

end
