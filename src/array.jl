#= Julia arrays can be reused directly. =#

#= For MetaModelica compatibility. =#
function array(args...)
  [args...]
end
