module ShouldFailTests
using MetaModelica
using Test

@test_throws MatchFailure @shouldFail(false)
@test_throws MatchFailure @shouldFail(true)

@test begin
  try
    @shouldFail throw(MatchFailure("My failure"))
    true
  catch e
    if !isa(e, MetaModelicaException)
      rethrow(e)
    end
    false
  end
end

end
