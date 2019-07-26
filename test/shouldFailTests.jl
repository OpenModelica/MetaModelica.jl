module ShouldFailTests
using MetaModelica
using Test

@test_throws MatchFailure @shouldFail(false) 
@test_throws MatchFailure @shouldFail(true) 

@test begin
  try
    @shouldFail throw(MatchFailure)
    true
  catch
    false
  end
end

end
