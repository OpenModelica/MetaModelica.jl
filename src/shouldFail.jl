"""
  This module provides the @shouldFail macro. 
  @shouldFail(arg) succeeds if arg fails, where arg is a local equation/statement.
"""
function genShouldFail(expr)
  quote
    local __have_failed__ = false
    try
      $(esc(expr))
      __have_failed__ = true
    catch
    end
    if __have_failed__
      throw(MatchFailure("Failure fail"))
    end
  end
end

macro shouldFail(expr)
  genShouldFail(expr)
end

export @shouldFail

