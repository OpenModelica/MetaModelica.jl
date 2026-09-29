module CompactedUniontypeTests

using MetaModelica
using Test

# `@CUniontype` fixture: a self-recursive uniontype whose variants form a
# chain of increasing detail (EMPTY/WILD have no fields, CREF adds three,
# one of which recurses on the uniontype itself) -- the shape `@CUniontype`
# requires (see its docstring), and the shape MetaModelica.compacted_tag_info
# targets.
@CUniontype Cref begin
  EMPTY()
  WILD()
  CREF(name::String, subscripts::Vector{Int}, rest::Cref)
end

function depth(c::CrefData)::Int
  @match c begin
    EMPTY() => 0
    WILD() => 0
    CREF(rest=r) => 1 + depth(r)
  end
end

@test depth(EMPTY()) == 0
@test depth(WILD()) == 0
@test depth(CREF("a", [1], CREF("b", Int[], EMPTY()))) == 2

# Keyword-argument patterns resolve through the same fieldorder-based destructuring.
@test (@match CREF("x", [1, 2], WILD()) begin
  CREF(name=n, subscripts=s) => (n, s)
end) == ("x", [1, 2])

# All-wild pattern (bare constructor call, no fields) still just checks the tag.
@test (@match EMPTY() begin
  EMPTY() => true
  _ => false
end) == true
@test (@match CREF("x", Int[], EMPTY()) begin
  EMPTY() => true
  _ => false
end) == false

# No matching case still throws MatchFailure, same as an ordinary struct pattern.
@test_throws MatchFailure (@match CREF("x", Int[], EMPTY()) begin
  EMPTY() => :empty
end)

# @matchcontinue: a case whose BODY throws is retried against later cases, exactly like a
# normal struct pattern -- proves handle_destruct's compacted-type path composes correctly
# with @matchcontinue's separate catch-and-retry wrapping (handle_match_case), not just
# @match's plain destructuring.
function nameOrFallback(c::CrefData)::String
  @matchcontinue c begin
    CREF(name=n) where n == "bad" => throw(MatchFailure("rejected name", n))
    CREF(name=n) => n
    _ => "none"
  end
end
@test nameOrFallback(CREF("ok", Int[], EMPTY())) == "ok"
@test nameOrFallback(CREF("bad", Int[], EMPTY())) == "bad"  # guard throws -> retried -> falls to the next CREF(name=n) arm
@test nameOrFallback(WILD()) == "none"  # no CREF arm applies at all -> falls to the wildcard

# Ordinary (non-compacted) struct patterns are completely unaffected by this extension --
# regression check that the new branch in handle_destruct only fires for registered types.
@test 1 == @match Cons(1, nil) begin
  Cons(head=x) => x
  _ => 2
end

end
