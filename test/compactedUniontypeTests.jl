module CompactedUniontypeTests

using MetaModelica
using Test

# Mimics a translator-generated "compacted" uniontype: several conceptually distinct
# record variants folded into ONE concrete struct with a tag field (needed for self- or
# mutually-recursive uniontype clusters where every variant sharing one type means
# ordinary `isa`-based struct-pattern dispatch does not apply -- see
# MetaModelica.compacted_tag_info's docstring). Self-referential fields are placed last
# so a partial `new(...)` can leave them genuinely #undef for variants that don't use them.

@enum ExprTag ADD_TAG NEG_TAG LIT_TAG

struct ExprData
  tag::ExprTag
  v::Int
  a::ExprData
  b::ExprData
  ExprData(tag::ExprTag, v::Int) = new(tag, v)
  ExprData(tag::ExprTag, v::Int, a::ExprData) = new(tag, v, a)
  ExprData(tag::ExprTag, v::Int, a::ExprData, b::ExprData) = new(tag, v, a, b)
end

LIT(v::Int) = ExprData(LIT_TAG, v)
NEG(a::ExprData) = ExprData(NEG_TAG, 0, a)
ADD(a::ExprData, b::ExprData) = ExprData(ADD_TAG, 0, a, b)

MetaModelica.compacted_tag_info(::typeof(LIT)) = (ExprData, :tag, LIT_TAG, (:v,))
MetaModelica.compacted_tag_info(::typeof(NEG)) = (ExprData, :tag, NEG_TAG, (:a,))
MetaModelica.compacted_tag_info(::typeof(ADD)) = (ExprData, :tag, ADD_TAG, (:a, :b))

function evalExpr(e::ExprData)::Int
  @match e begin
    LIT(v) => v
    NEG(a) => -evalExpr(a)
    ADD(a, b) => evalExpr(a) + evalExpr(b)
  end
end

@test evalExpr(LIT(3)) == 3
@test evalExpr(NEG(LIT(5))) == -5
@test evalExpr(ADD(LIT(3), NEG(LIT(4)))) == -1

# Keyword-argument patterns resolve through the same fieldorder-based destructuring.
@test (@match ADD(LIT(2), LIT(9)) begin
  ADD(a=x, b=y) => evalExpr(x) + evalExpr(y)
end) == 11

# All-wild pattern (bare constructor call, no fields) still just checks the tag.
@test (@match LIT(7) begin
  LIT() => true
  _ => false
end) == true
@test (@match ADD(LIT(1), LIT(1)) begin
  LIT() => true
  _ => false
end) == false

# No matching case still throws MatchFailure, same as an ordinary struct pattern.
@test_throws MatchFailure (@match NEG(LIT(1)) begin
  LIT(v) => v
end)

# @matchcontinue: a case whose BODY throws is retried against later cases, exactly like a
# normal struct pattern -- proves handle_destruct's compacted-type path composes correctly
# with @matchcontinue's separate catch-and-retry wrapping (handle_match_case), not just
# @match's plain destructuring.
function evalOrFallback(e::ExprData)::Int
  @matchcontinue e begin
    LIT(v) where v < 0 => throw(MatchFailure("negative literal", v))
    LIT(v) => v
    _ => -999
  end
end
@test evalOrFallback(LIT(5)) == 5
@test evalOrFallback(LIT(-1)) == -1  # guard throws -> retried -> falls to the next LIT(v) arm
@test evalOrFallback(ADD(LIT(1), LIT(2))) == -999  # no LIT arm applies -> falls to the wildcard

# Ordinary (non-compacted) struct patterns are completely unaffected by this extension --
# regression check that the new branch in handle_destruct only fires for registered types.
@test 1 == @match Cons(1, nil) begin
  Cons(head=x) => x
  _ => 2
end

end
