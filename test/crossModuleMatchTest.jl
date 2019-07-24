module CrossModuleTest
include("crossModule.jl")
import .CrossModule
using Test

function callIsAC(c)
  CrossModule.isC(c)
end

c = CrossModule.C()
@test callIsAC(c) == true

end
