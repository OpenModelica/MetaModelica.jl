module MetaModelica

import MacroTools
import MacroTools: @capture
import ExportAll
  #=
  Have to treat the types slightly different.
  Precompilation of the types need to occur before everything else
=#
include("metaModelicaTypes.jl")
import .MetaModelicaTypes
using .MetaModelicaTypes
include("union.jl")
import .UniontypeDef
using .UniontypeDef
include("list.jl")
import .ListDef
using .ListDef
include("matchcontinue.jl")
include("functionInheritance.jl")
include("metaRuntime.jl")
include("shouldFail.jl")
#include("Mutable.jl")

export @match, @matchcontinue, MatchFailure, ModelicaReal, ModelicaInteger
export @Uniontype, @Record, @UniontypeDecl, @ExtendedFunction, @ExtendedAnonFunction
export List, list, Nil, nil, Cons, cons, =>, Option, SOME, NONE, SourceInfo, SOURCEINFO
export @do_threaded_for, <|, @shouldFail, sourceInfo

include("exportmetaRuntime.jl")
include("dangerous.jl")
include("array.jl")
#======Expose libraries=======#
include("ArrayUtil.jl")
include("ListUtil.jl")
#=============================#
end
