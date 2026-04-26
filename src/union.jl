#=
Implementation of tagged unions for MetaModelica.jl
They can be used in that way with match.jl
=#

#= Example:
#@Uniontype number begin
#    @Record real begin
#    r::Real
#    end
#    @Record img begin
#    r::Real
#    i::Real
#    end
#end
# Or for short:
#@Uniontype number begin
#    @Record real r::Real
#    @Record img r::Real i::Real
#end
# This is syntactic sugar for:
#  abstract type number end
#  struct real <: number
#   r
#  end
#  struct img <: number
#   r
#   i
#  end
=#

#=
TODO: Sometimes when people use type aliasing @Uniontype will not know about the specific type during compilation time
=#
module UniontypeDef

include("metaModelicaTypes.jl")
import .MetaModelicaTypes
using MacroTools

function makeRecord(recordExpr::Expr)
  local arr = []
  local sourceInfo = nothing
  for i in recordExpr.args
    if typeof(i) == Expr
      push!(arr, (i, sourceInfo))
    elseif typeof(i) <: LineNumberNode
      sourceInfo = i
    end
  end
  return [(el[1].args[3], el[1].args[4], el[2]) for el in arr]
end

function makeTuple(name, fields)
  return quote
    ($name, $fields)
  end
end

function isLineNumberNode(a, lines::LineNumberNode)
  if typeof(a) <: LineNumberNode
    a.file == Symbol(@__FILE__)
  else
    false
  end
end

function replaceLineNum(a::Expr, lines::LineNumberNode)
  replace!(arg -> isLineNumberNode(arg, lines) ? lines : arg, a.args)
  for n in a.args
    replaceLineNum(n, lines)
  end
end

function replaceLineNum(a::Any, lines::LineNumberNode) end

#=
Parametric support.

Two opt-in shapes, both additive and backward compatible:

(A) Parametric outer uniontype:
      @Uniontype Container{T} begin
        @Record BOX begin x::T end
      end
    expands to
      abstract type Container{T} end
      struct BOX{T} <: Container{T} x::T end
    Every variant inherits the uniontype's parameters so that
    BOX{Int} <: Container{Int}.

(B) Parametric per-record variant:
      @Uniontype Value begin
        @Record WRAP{T} begin x::T end
      end
    expands to
      abstract type Value end
      struct WRAP{T} <: Value x::T end
    The record explicitly names its own parameters.

A record may combine both. When the outer is parametric and the record
is written without a curly, the outer parameters are propagated.
=#
function makeUniontypes(name, records, lineNode::LineNumberNode; mutable = false)
  local outerParams::Vector{Any} = Any[]
  local abstractHead = name
  local superExpr = name
  if isa(name, Expr) && name.head === :curly
    outerParams = name.args[2:end]
    abstractHead = name
    superExpr = name
  end
  recordsArray1 = Array.(records)
  recordsArray2 = recordsArray1[1]
  constructedRecords = []
  for r in recordsArray2
    structName = r[1]
    if !isempty(outerParams)
      if isa(structName, Symbol)
        structName = Expr(:curly, structName, outerParams...)
      elseif isa(structName, Expr) && structName.head === :curly
        # Outer params come first, record's own params follow.
        baseSym = structName.args[1]
        recordParams = structName.args[2:end]
        existingSet = Set(recordParams)
        merged = Any[baseSym]
        for p in outerParams
          if !(p in existingSet)
            push!(merged, p)
          end
        end
        append!(merged, recordParams)
        structName = Expr(:curly, merged...)
      end
    end
    recordNode = if ! mutable
      quote
        struct $(structName) <: $superExpr
          $(r[2])
        end
      end
    else
      quote
        mutable struct $(structName) <: $superExpr
          $(r[2])
        end
      end
    end
    replaceLineNum(recordNode, isa(r[3], Nothing) ? lineNode : r[3])
    push!(constructedRecords, recordNode)
  end
  #= Construct the Union =#
  res = quote
    abstract type $abstractHead end
    $(constructedRecords...)
  end
  # Make debugging and profiling easier by pretending the record was
  # allocated in the source file where the macro was invoked
  replaceLineNum(res, lineNode)
  return res
end

"""
  Creates a uniontype consisting of 0...N records.

  Two call forms:

  - `@Uniontype Name body`             — abstract type + records, no docstring.
  - `@Uniontype "text" Name body`      — as above, plus attach `"text"` as
                                         the docstring on the abstract type.

  The docstring-first form exists because the plain macro expands to a
  multi-form block (one `abstract type` plus N `struct`s), which Julia's
  docstring machinery rejects as a prefix-string target. The leading-string
  form works around that by registering the docstring post-hoc via
  `@doc str name` once the binding exists.
"""
macro Uniontype(args...)
  if length(args) >= 2 && args[1] isa AbstractString
    docstr = args[1]
    name = args[2]
    records = args[3:end]
  else
    docstr = nothing
    name = args[1]
    records = args[2:end]
  end
  recordCollection = [makeRecord(r) for r in records]
  core = makeUniontypes(name, recordCollection, __source__)
  if docstr === nothing
    return esc(core)
  end
  return esc(quote
    $core
    @doc $docstr $name
  end)
end

"""
  Creates a mutable uniontype consisting of 0...N records. Same call forms
  as [`@Uniontype`](@ref): optional leading `String` becomes the docstring.
"""
macro Mutable_Uniontype(args...)
  if length(args) >= 2 && args[1] isa AbstractString
    docstr = args[1]
    name = args[2]
    records = args[3:end]
  else
    docstr = nothing
    name = args[1]
    records = args[2:end]
  end
  recordCollection = [makeRecord(r) for r in records]
  core = makeUniontypes(name, recordCollection, __source__; mutable = true)
  if docstr === nothing
    return esc(core)
  end
  return esc(quote
    $core
    @doc $docstr $name
  end)
end

""" Creates a record belonging to a Uniontype """
macro Record(name, fields...)
  makeTuple(name, fields)
end

#= It is "possible" to manipulate the Julia ast during compilation time so that all declaration of a uniontype creates a module-top-level abstract type definition. I leave that as a exercise to the reader of this comment :D =#
macro UniontypeDecl(uDecl)
  esc(quote
        abstract type $uDecl end
      end)
end

export @Uniontype, @Record, @UniontypeDecl, @Mutable_Uniontype

end
