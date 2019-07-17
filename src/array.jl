#= It seems that we can just reuse the Julia arrays straight away=#
#= Addendum, the only difference seems to be that  MetaModelica arrays internally keep track on how many elements it contains=#

#= To create MArrays=#
function array(args...)
  [args...]
end
#=Currently use JArray as MArray=#
MArray = Array
