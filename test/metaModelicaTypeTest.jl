module MetaModelicaTypeTest

using MetaModelica
using Test

function f(a::ModelicaReal, b::ModelicaReal)::ModelicaReal
    return a + b
end

function f2(a::ModelicaInteger)::ModelicaInteger
    return a
end        
    
@test_throws MethodError f(true, true)

@test_throws MethodError f(true, 1)

@test f2(1) + f2(1) == 2

end
