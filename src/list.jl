/#
 # This file is part of OpenModelica.
 #
 # Copyright (c) 1998-Current year, Open Source Modelica Consortium (OSMC),
 # c/o Linköpings universitet, Department of Computer and Information Science,
 # SE-58183 Linköping, Sweden.
 #
 # All rights reserved.
 #
 # THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 # THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 # ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 # RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 # ACCORDING TO RECIPIENTS CHOICE.
 #
 # The OpenModelica software and the Open Source Modelica
 # Consortium (OSMC) Public License (OSMC-PL) are obtained
 # from OSMC, either from the above address,
 # from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 # http://www.openmodelica.org, and in the OpenModelica distribution.
 # GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 #
 # This program is distributed WITHOUT ANY WARRANTY; without
 # even the implied warranty of  MERCHANTABILITY or FITNESS
 # FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 # IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 #
 # See the full OSMC Public License conditions for more details.
 #
 #/

module ListDef

abstract type List{T} end

struct Nil{T} <: List{T} end

struct Cons{T} <: List{T}
  head::T
  tail::List{T}
end

#= 
  These promotion rules might seem a bit odd. Still it is the most efficient way I found of casting immutable lists
  If someone see a better alternative to this approach please fix me :). Basically I create a new list in O(N) * C time 
  with the type we cast to. Also, do not create new conversion strategies without measuring performance as they will call themselves 
  recursivly 
+=#

Base.convert(::Type{List{S}}, x::Cons{T}) where {S, T <: S} = let
  List(S, promote(x)...)
end

Base.convert(t::Type{Cons{S}}, x::Cons{T}) where {S, T <: S} = let
  List(S, promote(x)...)
end

Base.convert(::Type{List{T}}, x::Nil{Any}) where {T} = let
  Nil{T}()
end

Base.convert(::Type{Nil{T}}, x::Nil) where {T} = let
  Nil{T}()
end

Base.convert(::Type{List{S}}, x::Nil{T}) where {S, T <: S} = let
  Nil{S}()
end

Base.convert(::Type{T}, a::List) where {T <: List} = let
  a isa T ? a : List(eltype(T), promote(a)...)
end

#= Identity cases =#
Base.convert(::Type{List{T}}, x::Cons{T}) where {T} =  x

Base.convert(::Type{Cons{T}}, x::Cons{T}) where {T} = x

Base.convert(::Type{List{T}}, x::Nil{T}) where {T} = x

Base.convert(::Type{List{Any}}, x::Nil{Any}) = x

Base.convert(::Type{List{T}}, x::List{T}) where {T} = x

Base.convert(::Type{List}, x::List) = x

Base.promote_rule(a::Type{List{T}}, b::Type{List{S}}) where {T,S} = let
  el_same(promote_type(T,S), a, b)
end

#= Definition of eltype =#
Base.eltype(::Type{List{T}}) where {T} = let
  T
end

Base.eltype(::Type{Cons{T}}) where {T} = let
  T
end

Base.eltype(::List{T}) where {T} = let
  T
end

Base.eltype(::Cons{T}) where {T} = let
  T
end

#= For "Efficient" casting... O(N) * C" =#
List(T::Type #= Hack.. =#, args...) = let
  local lst::List{T} = nil(T)
  for e in first(args)
    lst = Cons{T}(e, lst)
  end
  lst
end

nil(T) = Nil{T}()
nil() = Nil{Any}()
list() = nil()

#= Support for primitive constructs. Numbers. Integer bool e.t.c =#
function list(els::T...)::List{T} where {T <: Number}
  local lst::List{T} = nil()
  for i in length(els):-1:1
    lst = Cons{T}(els[i], lst)
  end
  lst
end

#= Strings can also be considered a primitive...=#
function list(els::T...)::List{T} where {T <: AbstractString}
  local lst::List{T} = nil()
  for i in length(els):-1:1
    lst = Cons{T}(els[i], lst)
  end
  lst
end

#= Support hieractical constructs. Concrete elements =#
function list(els...)::List
  local S::Type = eltype(els)
  local lst::List{S} = Nil{S}()
  for i in length(els):-1:1
    lst = Cons{S}(els[i], lst)
  end
  lst
end

#= Support generic list for the other cases =#
function list(els::Tuple{Type}...)::List
  local lst::List = nil()
  for i in length(els):-1:1
    lst = Cons(els[i], lst)
  end
  lst
end

cons(v::T, ::Nil{Any}) where {T} = Cons{T}(v, nil(T))
cons(v, ::Nil{T}) where {T} = Cons{T}(v, nil(T))
cons(v, l::Cons{T}) where {T} = Cons{T}(v, l)

# Right-associative operator ; conflicts with => in match expressions...
Base.Pair(v, l::List{T}) where {T} = cons(v, l)
# Suggestion for new operator <| also right assoc <| :), See I got a hat
<|(v, lst::List{T}) where{T}= cons(v, lst)

Base.length(::Nil) = 0
function Base.length(l::List)::Integer
    local n::Int64 = 0
    for _ in l
        n += 1
    end
    n
end

Base.iterate(::List, ::Nil) = nothing
function Base.iterate(l::List, state::Cons = l)
    state.head, state.tail
end

#=
  For list comprehension. Unless we switch to mutable structs this is the way to go I think.
  Seems to be more efficient then what the omc currently does.
=#
list(F, C::Base.Generator) = let
  list(collect(Base.Generator(F, C))...)
end

#= Comprehension without a function(!) =#
list(C::Base.Generator) = let
  #= Just apply the element to itself =#
  list(i->i, C)
end

#= Adds the ability for Julia to flatten MMlists =#
list(X::Base.Iterators.Flatten) = let
  list([X...]...)
end

#Reductions
list(X::Base.Generator{Base.Iterators.ProductIterator{Y}, Z}) where {Y,Z} = let
  x = collect(X)
  list(list(i...) for i in view.([x], 1:size(x, 1), :))
end

#=
Generates the transformation:

 @do_threaded_for expr with (iter_names) iterators =>
  $expr for $iterator_names in list(zip($iters...)...)
=#
function make_threaded_for(expr, iter_names, ranges)
  iterExpr::Expr = Expr(:tuple, iter_names.args...)
  rangeExpr::Expr = ranges = [ranges...][1]
  rangeExprArgs = rangeExpr.args
  :($expr for $iterExpr in [ zip($(rangeExprArgs...))... ]) |> esc
end

macro do_threaded_for(expr::Expr, iter_names::Expr, ranges...)
  make_threaded_for(expr, iter_names, ranges)
end

#= Julia standard sort is pretty good =#
Base.sort(lst::List) = let
  list(sort([lst...])...)
end

#= Immutable list. List is short for it but cannot be used in all contexts=#
IList = List

export List, list, Nil, nil, Cons, cons, <|, IList
export @do_threaded_for

end
