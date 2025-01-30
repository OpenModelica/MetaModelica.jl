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
    if @capture(expr, lhs_._ = rhs_)
      if !isprimitivetype(typeof(lhs))
        Accessors.setmacro(identity, expr, overwrite=true)
      else
        quote
          $(esc(expr))
        end
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

function genNoSpecializedFunction(expr)
  local newExpr::Expr
  try
    if expr.head === :function
      if expr.args[1].head === :call
        funcCall = expr.args[1]
        body = expr.args[2]
        funcName = funcCall.args[1]
        args = funcCall.args[2:end]
        # Convert function name and arguments to strings for printing
        funcNameStr = string(funcName)
        argsStr = join(string.(args), ", ")
        println("Function name: ", funcNameStr)
        println("Arguments: ", argsStr)
        local newArgs = Expr[]
        global ARGS = args
        for arg in args
          push!(newArgs, :(@nospecialize($arg)))
        end
        newExpr = quote
          Base.@nospecializeinfer function $funcName($(newArgs...))
            $(body)
          end
        end
      else
        throw()
      end
    end
  catch
    error("@nospecialized can only be used on functions defined as function <name>(<arguments>).")
  end
    # Return the original expression unchanged
  return esc(newExpr)
end

"""
Takes a function declaration function <name>(<arguments>) and change it to
@nospecializeinfer function <name>(@nospecialize(a), @nospecialize(b), ..., @nospecialize(n))
"""
macro nospecialized(expr)
  res = genNoSpecializedFunction(expr)
  replaceLineNum(res, @__FILE__, __source__)
  res
end
