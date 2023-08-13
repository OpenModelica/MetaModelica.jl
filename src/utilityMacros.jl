import Setfield
import FastClosures
"""
  Helper function for the assignmacro, see @assign
  We have one case where we assign a immutable structure to an immutable structure or something to a primitive variable.
  If it is not a primitive we assign to a subcomponent of that structure. We then clone the structure with that particular field changed.
"""
function assignFunc(expr)
  res =
    if @capture(expr, lhs_._ = rhs_)
      if !isprimitivetype(typeof(lhs))
        Setfield.setmacro(identity, expr, overwrite=true)
      else
        quote
          $(esc(expr))
      end
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
  assignFunc(expr)
end

"""
  Wraps the @closure macro of FastClosures.
See the FastClosure package for more information.
"""
macro closure(expr)
  esc(FastClosures.wrap_closure(__module__, expr))
end
