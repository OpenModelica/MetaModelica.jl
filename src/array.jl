#= It seems that we can just reuse the Julia arrays straight away=#

#= For MetaModelica comptability =#
function array(args...)
  [args...]
end
