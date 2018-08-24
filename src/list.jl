abstract type List{T} end

struct Nil{T} <: List{T}
end

struct Cons{T} <: List{T}
    head::T
    tail::List{T}
end

nil(T) = Nil{T}()
nil() = Nil{Any}()

list() = nil()
function list(vs::T...) where {T}
  lst = nil(T)
  for i in length(vs):-1:1
    lst = vs[i] | lst
  end
  lst
end

cons(v::T, ::Nil{Any}) where {T} = Cons{T}(v, nil(T))
cons(v, ::Nil{T}) where {T} = Cons{T}(v, nil(T))
cons(v, l::Cons{T}) where {T} = Cons{T}(v, l)

# Right-associative operator ; conflicts with => in match expressions...
Base.Pair(v, l::List{T}) where {T} = cons(v, l)

Base.length(::Nil) = 0
function Base.length(l::Cons)
    n = 0
    for _ in l
        n += 1
    end
    n
end

Base.iterate(::List, ::Nil) = nothing
function Base.iterate(l::List, state::Cons = l)
    state.head, state.tail
end
export List, list, Nil, nil, Cons, cons, =>
