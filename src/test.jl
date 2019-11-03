using MetaModelica

struct A
  a
  b
end

var = A(1,2)
@info var
@<| var.a 5
println(var.a)
@info var
