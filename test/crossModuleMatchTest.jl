module CrossModuleTest
include("crossModule.jl")
import .CrossModule
using Test

function callIsAC()
  c::CrossModule.C = CrossModule.C()
  CrossModule.isC(c)
end

function callIsAC2()
  c::CrossModule.C = CrossModule.C()
  CrossModule.isC2(c)
end

@test callIsAC() == true

@test callIsAC2() == CrossModule.C

end
