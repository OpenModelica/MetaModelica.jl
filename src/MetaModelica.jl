module MetaModelica

include("MatchContinue.jl")

struct Cons{T}
  car::T
  cdr::Union{Cons{T},Nothing}
end

const List{T} = Union{Cons{T},Nothing}

export List, Cons

end
