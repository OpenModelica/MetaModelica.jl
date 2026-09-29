module TaggedUniontypeTests

using MetaModelica
using Test

#= @T_Uniontype: variants with disjoint fields, defaults (also in the middle of
   the field list), a self-reference, and a pre-declared abstract type. =#
@UniontypeDecl Shape

@T_Uniontype Shape begin
  SHAPE_NONE()
  CIRCLE(r::Float64, filled::Bool = false)
  RECT(w::Float64, h::Float64, filled::Bool = false, label::String)
  GROUP(parts::Vector{Shape}, parent::Shape)
end

@testset "@T_Uniontype layout" begin
  @test isconcretetype(ShapeImpl) && ShapeImpl <: Shape
  @test fieldnames(ShapeImpl) == (:tag, :r, :filled, :w, :h, :label, :parts, :parent)
  # A field with a default keeps its type; one without becomes nullable.
  @test fieldtype(ShapeImpl, :filled) === Bool
  @test fieldtype(ShapeImpl, :r) === Union{Nothing, Float64}
  # Self-references are concrete.
  @test fieldtype(ShapeImpl, :parts) === Union{Nothing, Vector{ShapeImpl}}
  @test fieldtype(ShapeImpl, :parent) === Union{Nothing, ShapeImpl}
end

@testset "@T_Uniontype constructors" begin
  c = CIRCLE(1.0)
  @test c isa ShapeImpl && c.r == 1.0 && c.filled == false && c.w === nothing
  @test CIRCLE(2.0, true).filled
  @test CIRCLE(; r = 3.0).r == 3.0
  # Positional needs all fields when a default is followed by a required one.
  r = RECT(1.0, 2.0, true, "a")
  @test (r.w, r.h, r.filled, r.label) == (1.0, 2.0, true, "a")
  @test_throws MethodError RECT(1.0, 2.0, "a")
  # Keyword form: defaulted fields may be left out anywhere.
  @test RECT(; w = 1.0, h = 2.0, label = "b").filled == false
  # Arguments are converted to the field types.
  @test CIRCLE(1).r === 1.0
  # Nullary variants of an immutable uniontype are one shared value.
  @test SHAPE_NONE() === SHAPE_NONE()
  g = GROUP([c, r], SHAPE_NONE())
  @test g.parts[2] === r
end

@testset "@T_Uniontype isvariant / variantof / valueConstructor" begin
  c = CIRCLE(1.0)
  @test isvariant(c, CIRCLE)
  @test !isvariant(c, RECT)
  @test !isvariant(1, CIRCLE)
  @test variantof(c) === CIRCLE
  @test variantof(SHAPE_NONE()) === SHAPE_NONE
  @test valueConstructor(c) == valueConstructor(CIRCLE(5.0))
  @test valueConstructor(c) != valueConstructor(SHAPE_NONE())
  # isvariant on ordinary types is isa.
  @test isvariant(1, Int)
  @test isvariant(nil, List)
  @test_throws ArgumentError isvariant(c, println)
end

area(s::Shape) = @match s begin
  SHAPE_NONE() => 0.0
  CIRCLE(r = r) => pi * r^2
  RECT(w, h) => w * h
  GROUP(parts = ps) => sum(area, ps; init = 0.0)
end

@testset "@T_Uniontype @match" begin
  @test area(SHAPE_NONE()) == 0.0
  @test area(RECT(2.0, 3.0, false, "")) == 6.0
  @test area(GROUP([RECT(1.0, 1.0, false, ""), RECT(2.0, 1.0, false, "")], SHAPE_NONE())) == 3.0
  @test (@match CIRCLE(1.0) begin
    RECT(__) => :rect
    CIRCLE(__) => :circle
  end) == :circle
  @test_throws MatchFailure (@match CIRCLE(1.0) begin
    RECT(__) => :rect
  end)
end

@testset "@T_Uniontype @assign" begin
  c = CIRCLE(1.0)
  @assign c.r = 2.0
  @test c.r == 2.0 && isvariant(c, CIRCLE)
end

@T_Uniontype mutable Counter begin
  COUNTER_EMPTY()
  COUNTER(n::Int = 0)
end

@testset "@T_Uniontype mutable" begin
  @test ismutabletype(CounterImpl)
  # Nullary variants of a mutable uniontype are fresh values.
  @test COUNTER_EMPTY() !== COUNTER_EMPTY()
  x = COUNTER()
  x.n += 1
  @test x.n == 1
  @test COUNTER(5).n == 5
end

#= @CUniontype additions: concrete self-reference, singletons, tag-based
   valueConstructor/variantof, @assign on a variant with an #undef tail. =#
@CUniontype Tree begin
  EMPTY()
  LEAF(key::Int, value::String)
  NODE(key::Int, value::String, left::Tree, right::Tree)
end

@testset "@CUniontype" begin
  @test fieldtype(TreeData, :left) === TreeData
  @test EMPTY() === EMPTY()
  l = LEAF(1, "a")
  @test isvariant(l, LEAF) && !isvariant(l, NODE)
  @test variantof(l) === LEAF
  @test valueConstructor(l) != valueConstructor(EMPTY())
  @assign l.value = "b"
  @test l.value == "b" && isvariant(l, LEAF)
  @test_throws ArgumentError (@assign l.left = EMPTY())
  n = NODE(2, "x", l, EMPTY())
  @assign n.right = LEAF(3, "c")
  @test n.right.key == 3
end

#= Only a field missing from some variant (and without a default) is nullable. =#
@T_Uniontype Stmt begin
  S_NOP(source::String)
  S_EXPR(exp::Int, source::String)
end

@testset "@T_Uniontype nullability" begin
  @test fieldtype(StmtImpl, :source) === String
  @test fieldtype(StmtImpl, :exp) === Union{Nothing, Int}
  @test S_NOP("a").exp === nothing
end

#= Pattern fields: positional then named works; unknown names, positional after
   named and repeated names are rejected when the pattern is expanded. =#
expandError(ex) = try
  @eval $ex
  ""
catch err
  sprint(showerror, err)
end

@testset "compacted patterns: field names" begin
  @test (@match RECT(2.0, 3.0, false, "") begin
    RECT(w, h = hh) => w * hh
  end) == 6.0
  @test occursin("has no field `wdth`",
                 expandError(:(@match CIRCLE(1.0) begin CIRCLE(wdth = x) => x end)))
  @test occursin("positional field after a named one",
                 expandError(:(@match RECT(1.0, 1.0, false, "") begin RECT(h = x, y) => x end)))
  @test occursin("binds a field twice",
                 expandError(:(@match RECT(1.0, 1.0, false, "") begin RECT(w, w = y) => y end)))
end

#= @CUniontype: the shared prefix must also be in the same order. =#
@testset "@CUniontype field order" begin
  @test occursin("in that order",
                 expandError(:(@CUniontype Swapped begin
                   SW_A(b::Int, a::String)
                   SW_B(a::String, b::Int, c::Int)
                 end)))
end

#= Qualified pattern heads: constructors from another module. =#
module Inner
  using MetaModelica
  @T_Uniontype Op begin
    ADD(a::Int, b::Int)
    NEG(a::Int)
  end
end

evalOp(op) = @match op begin
  Inner.ADD(a, b) => a + b
  Inner.NEG(a = x) => -x
end

@testset "qualified patterns" begin
  @test evalOp(Inner.ADD(1, 2)) == 3
  @test evalOp(Inner.NEG(4)) == -4
  @test isvariant(Inner.NEG(1), Inner.NEG)
end

end
