module TestMetaModelica

using MetaModelica
using Base.Test

function abc()
  for i in 1:1000
    @match Cons(1,nothing) begin
      Cons(car=x) => x
      _ => 2
    end
  end
end

end
