#= Julia arrays can be reused directly. =#

#= For MetaModelica compatibility. Lists give an array of any list (arrayElemType). =#
function array(args...)
  local arr = [args...]
  return convert(Vector{arrayElemType(eltype(arr))}, arr)
end
