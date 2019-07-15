module FunctionExtensionTest

using MetaModelica
using Test

function callOneArgNoDefault1(a)
  a
end

@ExtendedFunction callA1 callOneArgNoDefault1(a=1)

@test callA1() == 1

function callOneArgNoDefault2(a,b)
  a + b
end
  
@ExtendedFunction callA1 callOneArgNoDefault2(a=1, b =1)

@test callA1() == 2

function pathString(usefq=true)
  usefq
end

@ExtendedFunction pathStringNoQual pathString(usefq=false)

@test pathStringNoQual() != pathString()

@ExtendedFunction pathStringNoQualInv pathString(usefq=true)

@test pathStringNoQualInv() == pathString()

function foo(a,b=1,c=2,d=3,e=4)
  (a,b,c,d,e)
end
  
@ExtendedFunction foo3 foo(d=2000)

@test sum(foo3(1)) > 2000

@ExtendedFunction foo2 foo(a = 1, c=4, d=6)

@test sum(foo2()) == sum((1, 1, 4, 6 ,4))

# = Testing inheritance in several steps #=
  
function fooBar(a=1)
 a
end

@ExtendedFunction fooBar1 fooBar(a=4)

@ExtendedFunction fooBar2 fooBar1(a=100)

@test fooBar1() == 4

@test fooBar2() == 100 

#= Testing anon functions =#

f = @ExtendedAnonFunction fooBar()

@test 1 == f()

f = @ExtendedAnonFunction fooBar(a=500)

@test f() == 500

function zeroArgFoo()
  5
end

function takeFoo(a)
  a()
end

@test takeFoo(@ExtendedAnonFunction zeroArgFoo()) == 5

@test takeFoo(@ExtendedAnonFunction fooBar1()) == 4

function pathString(path::String, delimiter::String=".", usefq::Bool=true, reverse::Bool=false)::String
  usefq
end

@test 5 == begin
  function zeroArgFoo()
    5
  end
  function fooFoo()
    takeFoo(@ExtendedAnonFunction zeroArgFoo())
  end
  fooFoo()
end

end
