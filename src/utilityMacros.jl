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
  Decompose an assignment of the form `name.f1.f2... = rhs` into
  `(name::Symbol, [:f1, :f2, ...], rhs)`. Returns an empty path for the bare
  `name = rhs`. Returns `nothing` when the LHS is anything else (indexing,
  destructuring, ...) so the caller can fall through to the verbatim form.
"""
function decomposeAssign(s)
  s isa Expr || return nothing
  s.head === :(=) || return nothing
  lhs = s.args[1]
  rhs = s.args[2]
  if lhs isa Symbol
    return (lhs, Symbol[], rhs)
  end
  path = Symbol[]
  cur = lhs
  while cur isa Expr && cur.head === :. && length(cur.args) == 2
    fieldArg = cur.args[2]
    if fieldArg isa QuoteNode && fieldArg.value isa Symbol
      pushfirst!(path, fieldArg.value)
    elseif fieldArg isa Symbol
      pushfirst!(path, fieldArg)
    else
      return nothing
    end
    cur = cur.args[1]
  end
  cur isa Symbol || return nothing
  return (cur, path, rhs)
end

const _AssignUpdate = Tuple{Vector{Symbol}, Any, Union{Nothing,LineNumberNode}}

"""
  Wrap `inner` in a `:block` Expr prefixed with `ln` so Julia attaches the
  source location to the synthesized code. Falls back to `inner` if `ln` is
  `nothing`.
"""
function _withLine(ln::Union{Nothing,LineNumberNode}, inner)
  ln === nothing && return inner
  return Expr(:block, ln, inner)
end

"""
  Build a NamedTuple-literal Expr representing the patch for a (sub)object.
  `readExpr` is an already-escaped Expr that reads the (sub)object the patch
  is applied to; it is used to construct `readExpr.fieldName` for nested
  sub-objects so that recursive `setproperties` calls share the same root
  read.

  `updates` is a vector of `(path::Vector{Symbol}, rhs, line)` whose first
  path segment selects the field within this NamedTuple. The `line` carries
  the LineNumberNode of the originating assignment and is attached to any
  synthesized intermediate code so stack traces point to user source.
  A direct overwrite of a field (empty remaining path) supersedes any
  nested updates that came before it; nested updates that follow the direct
  overwrite are applied on top of the overwritten value via a `let` binding
  so the RHS is evaluated once.
"""
function buildPatchExpr(readExpr, updates::Vector{_AssignUpdate})
  order = Symbol[]
  groups = Dict{Symbol, Vector{_AssignUpdate}}()
  for (path, rhs, ln) in updates
    first = path[1]
    if !haskey(groups, first)
      push!(order, first)
      groups[first] = _AssignUpdate[]
    end
    push!(groups[first], (path[2:end], rhs, ln))
  end
  ntArgs = Any[]
  for field in order
    g = groups[field]
    directIdx = findlast(t -> isempty(t[1]), g)
    if directIdx === nothing
      subRead = Expr(:., readExpr, QuoteNode(field))
      subPatch = buildPatchExpr(subRead, g)
      ln = g[end][3]
      push!(ntArgs, Expr(:(=), field, _withLine(ln, :($Accessors.setproperties($subRead, $subPatch)))))
    else
      _, directVal, directLn = g[directIdx]
      after = g[directIdx+1:end]
      if isempty(after)
        push!(ntArgs, Expr(:(=), field, _withLine(directLn, esc(directVal))))
      else
        tmp = gensym(:base)
        subPatch = buildPatchExpr(tmp, after)
        afterLn = after[end][3]
        body = :($Accessors.setproperties($tmp, $subPatch))
        let_block = Expr(:let,
                         Expr(:(=), tmp, esc(directVal)),
                         _withLine(afterLn, body))
        push!(ntArgs, Expr(:(=), field, _withLine(directLn, let_block)))
      end
    end
  end
  return Expr(:tuple, ntArgs...)
end

"""
  Block form of `@assign`. Walks `blockExpr.args`, groups consecutive
  field-assignments by their root variable, and folds each group into a
  single `Accessors.setproperties` call so the root struct is reallocated
  exactly once per group. Plain `name = rhs` assignments and other
  statements are emitted verbatim and act as group separators. Each
  synthesized call carries the source line of the last assignment that
  contributed to it, so stack traces point to user code.
"""
function assignBlockFunc(blockExpr::Expr)
  @assert blockExpr.head === :block
  out = Expr(:block)
  rootSym = Ref{Union{Nothing,Symbol}}(nothing)
  updates = _AssignUpdate[]
  lastLine = Ref{Union{Nothing,LineNumberNode}}(nothing)
  flush! = function ()
    if rootSym[] !== nothing
      patch = buildPatchExpr(esc(rootSym[]), updates)
      ln = updates[end][3]
      assignExpr = :($(esc(rootSym[])) = $Accessors.setproperties($(esc(rootSym[])), $patch))
      push!(out.args, _withLine(ln, assignExpr))
      rootSym[] = nothing
      empty!(updates)
    end
  end
  for s in blockExpr.args
    if s isa LineNumberNode
      lastLine[] = s
      push!(out.args, s)
      continue
    end
    decomp = decomposeAssign(s)
    if decomp === nothing
      flush!()
      push!(out.args, esc(s))
      continue
    end
    root, path, rhs = decomp
    if isempty(path)
      flush!()
      push!(out.args, esc(s))
      continue
    end
    if rootSym[] === nothing || rootSym[] === root
      rootSym[] = root
      push!(updates, (path, rhs, lastLine[]))
    else
      flush!()
      rootSym[] = root
      push!(updates, (path, rhs, lastLine[]))
    end
  end
  flush!()
  return out
end

"""
  This macro reimplements the MetaModelica assignment semantics using
  setfield to assign to variables.
  For assignments using primitives, the regular Julia assignment is generated.
  For cases where deeply nested immutable structures are manipulated we use setfield
E.g.:
  a.b.c = 5
  Where a is a nested immutable struct

  A `begin ... end` block form is also supported. Consecutive assignments
  to the same root variable are folded into a single `setproperties` call,
  reallocating the struct once instead of once per field.

  ```julia
  @assign begin
    obj.a = 1
    obj.b = 2
    obj.c.x = 5
    obj.c.y = 6
  end
  ```

  expands to one allocation for `obj` and one for `obj.c`. RHS expressions
  in the same group are evaluated against the pre-batch object, so a later
  assignment that reads a field an earlier assignment wrote will see the
  OLD value. Split the block when sequential semantics matter.
"""
macro assign(expr)
  res = if expr isa Expr && expr.head === :block
    assignBlockFunc(expr)
  else
    assignFunc(expr)
  end
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
