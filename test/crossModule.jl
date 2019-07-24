module CrossModule
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

end
