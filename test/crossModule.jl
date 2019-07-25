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
    A(__) => false
    B(__) => false
    C(__ ) => true
  end
end

function isC2(a::S)
  @match a begin
    A(__) => A
    B(__) => B
    C(__ ) => C
  end
end

@exportAll()

end
