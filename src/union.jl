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

module UniontypeDef

function makeRecord(recordExpr::Expr)
  local arr = []
  for i in recordExpr.args
    if typeof(i) == Expr
      push!(arr, i)
    end
  end
  local res = []
  for el in arr
    push!(res, (el.args[3], el.args[4]))
  end
  return [(el.args[3], el.args[4]) for el in arr]
end

function makeTuple(name, fields)
  return quote ($name, $fields) end
end

function makeUniontypes(name, records)
  recordsArray1 = Array.(records)
  recordsArray2 = recordsArray1[1]
  constructedRecords = []
  for r in recordsArray2
    push!(constructedRecords,
          quote
          struct $(r[1]) <: $name
          $(r[2])
          end
          end)
  end
  #= Construct the Union =#
  return quote
    abstract type $name end
  $(constructedRecords...)
end
end

#= Creates a uniontype consisting of 0...N records =#
macro Uniontype(name, records...)
  recordCollection = [makeRecord(r) for r in records]
  esc(makeUniontypes(name, recordCollection))
end

#= Creates a record belonging to a Uniontype =#
macro Record(name, fields...)
  makeTuple(name, fields)
end

#= It is "possible" to manipulate the Julia ast during compilation time so that all declaration of a uniontype creates a module-top-level abstract type definition. I leave that as a exercise to the reader of this comment :D =#
macro UniontypeDecl(uDecl)
  esc(quote
      abstract type $uDecl end
      end)
end

export @Uniontype, @Record, @UniontypeDecl

end
