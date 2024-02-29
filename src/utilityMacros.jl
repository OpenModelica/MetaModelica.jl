#import Setfield
import FastClosures
import Accessors
"""
  Helper function for the assignmacro, see @assign
  We have one case where we assign a immutable structure to an immutable structure or something to a primitive variable.
  If it is not a primitive we assign to a subcomponent of that structure. We then clone the structure with that particular field changed.
"""
function assignFunc(expr)
  res =
    if @capture(expr, lhs_.sub_.sub_ = rhs_)
      Accessors.setmacro(identity, expr, overwrite=true)
    elseif @capture(expr, lhs_.sub_ = rhs_) #= Captures a.b=#
      tmp = Accessors.setmacro(identity, expr, overwrite=true)
      #=
      The second condition is a temporary fix.
      It is due to what seems to be a bug
      for setfield in which it consumes a lot of memory if used for a linked list
      =#
      sym = :($sub)
      quote
        #local tmp1 = $(esc(lhs))
        #local tmp2 = $(esc("$sym"))
        #local tmp3 = Symbol(tmp2)
        #local tmp4 = getproperty(tmp1, tmp3)
        #@assert(!(tmp4 isa List))
        #@assert(!(tmp4 isa Vector))
        $tmp
      end
    elseif @capture(expr, lhs_.sub__= rhs_)
      quote
        $tmp
      end
    else
      quote
        $(esc(expr))
      end
    end
  return res
end

"""
  This macro reimplements the MetaModelica assignment semantics using
  setfield to assign to variables.
  For assignments using primitives, the regular Julia assignment is generated.
  For cases where deeply nested immutable structures are manipulated we use setfield
E.g.:
  a.b.c = 5
  Where a is a nested immutable struct
"""
macro assign(expr)
  res = assignFunc(expr)
  replaceLineNum(res, @__FILE__, __source__)
  res
end

"""
  Wraps the @closure macro of FastClosures.
See the FastClosure package for more information.
"""
macro closure(expr)
  esc(FastClosures.wrap_closure(__module__, expr))
end
