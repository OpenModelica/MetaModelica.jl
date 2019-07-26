module CrossModule

using ExportAll
using MetaModelica

abstract type S end;

struct A <: S
end

struct B <:S 
end

struct C <: S
end

function isC(a::S)
  @match a begin
    A() => false
    B() => false
    C() => true
  end
end

function isC2(a::S)
  @match a begin
    A() => A
    B() => B
    C() => C
  end
end

@exportAll()

end
