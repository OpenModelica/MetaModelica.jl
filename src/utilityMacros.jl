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

function genNoSpecializedFunction(expr, mod::Module = @__MODULE__;
                                   strict::Bool = false,
                                   macroName::String = "@nospecialized")
  local parts
  try
    parts = MacroTools.splitdef(expr)
  catch
    error("$macroName expects a function definition (long form, short form, with or without return-type, where-clause, or keyword arguments).")
  end
  strict && _assertNoAnyInArgs(parts, macroName, mod)
  parts[:args]   = Any[:(@nospecialize($a)) for a in parts[:args]]
  parts[:kwargs] = Any[:(@nospecialize($k)) for k in parts[:kwargs]]
  rebuilt = MacroTools.combinedef(parts)
  newExpr = quote
    Base.@nospecializeinfer $rebuilt
  end
  return esc(newExpr)
end

_containsAny(T) = T === :Any
function _containsAny(T::Expr)
  found = Ref(false)
  MacroTools.postwalk(T) do node
    node === :Any && (found[] = true)
    node
  end
  return found[]
end

function _resolvedIsAny(T_expr, mod::Module)
  try
    resolved = Core.eval(mod, T_expr)
    return resolved === Any
  catch
    return false
  end
end

function _unboundWhereParams(parts)
  bad = String[]
  for wp in get(parts, :whereparams, Any[])
    if wp isa Symbol
      push!(bad, string(wp))
    end
  end
  return bad
end

function _assertNoAnyInArgs(parts, macroName::String, mod::Module)
  offenders = String[]
  for (label, args) in (("argument", get(parts, :args, Any[])),
                        ("keyword argument", get(parts, :kwargs, Any[])))
    for arg in args
      name, T, _slurp, _default = MacroTools.splitarg(arg)
      if _containsAny(T) || _resolvedIsAny(T, mod)
        push!(offenders, "$label `$(name === nothing ? string(arg) : string(name))`")
      end
    end
  end
  for wp in _unboundWhereParams(parts)
    push!(offenders, "where-parameter `$wp` (unconstrained, behaves as `<: Any`)")
  end
  if !isempty(offenders)
    error("$macroName requires every argument to carry a non-`Any` type annotation. " *
          "Offenders: " * join(offenders, ", ") * ".")
  end
  return nothing
end

"""
    @nospecialized function name(a, b, ...; k = ..., ...)::R where {T, ...}
        ...
    end

Rewrites a function definition so every positional and keyword argument is wrapped
in `@nospecialize`, and the whole definition is wrapped in `Base.@nospecializeinfer`.
The short form `name(args...) = body`, return-type annotations, `where` clauses, and
keyword arguments are all supported.

Equivalent rewrite for a long-form definition:

    @nospecializeinfer function name(@nospecialize(a), @nospecialize(b), ...; @nospecialize(k = ...))::R where {T, ...}
        ...
    end
"""
macro nospecialized(expr)
  res = genNoSpecializedFunction(expr)
  replaceLineNum(res, @__FILE__, __source__)
  res
end

"""
    @strict_nospecialized function name(a::T, b::U, ...; k::K = ..., ...)::R where {T <: Bound, ...}
        ...
    end

Same rewrite as `@nospecialized`, but rejects any signature in which an argument type
can resolve to `Any`. Rejection happens at macro-expansion time, before the method is
defined. Three layers of checking:

1. **Syntactic.** A missing annotation, an explicit `::Any`, or `Any` appearing
   anywhere in the type expression (`Vector{Any}`, `Union{Int, Any}`,
   `Vararg{Any}`, ...) is rejected.
2. **Alias resolution.** The annotation is evaluated in the calling module
   (`Core.eval(__module__, T)`). If it resolves to `Any` (covers
   `const MyAlias = Any; f(a::MyAlias)` and `Union{Int, Any}` collapsing to
   `Any`), the definition is rejected. If the name is not yet bound (forward
   references, where-parameters), the alias check falls back silently and only
   the syntactic check applies for that argument.
3. **Where-parameters.** Unconstrained type parameters such as `f(a::T) where {T}`
   are rejected because `T <: Any` makes them morally equivalent to `::Any`.
   Bounded parameters (`where {T <: Number}`) are accepted.

The cost is paid at macro-expansion time only. The generated method body is
identical to `@nospecialized`.

The return-type annotation is not constrained; only argument annotations are checked.
For run-time guarantees that call-sites are inferred concretely, use
`Test.@inferred` or `JET.@report_call` instead; those run after definitions exist.
"""
macro strict_nospecialized(expr)
  res = genNoSpecializedFunction(expr, __module__; strict = true, macroName = "@strict_nospecialized")
  replaceLineNum(res, @__FILE__, __source__)
  res
end
