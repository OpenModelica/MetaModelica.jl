"""
  Implementation of function inheritance, enabling functions to extend other functions.
  @ExtendedFunction pathStringNoQual pathString(usefq=false)

  This means defining a new function pathStringNoQual equal to pathString. However,
  the usefq argument now has a different default value.

  We do so by creating a new function but passing the redefined arguments to it.

  It is also possible to define an anonymous function using the following syntax:

  @ExtendedAnonFunction pathString(usefq=false)

  The latter defines a lambda function that extends pathString. However, the default values of the
  parameters can be changed MetaModelica style.

@Author John Tinnerholm, same license as the rest of this package

TODO: @ExtendedAnonFunction and @ExtendedFunction do not work for inline
      expressions because some variables are not available at expansion time.
      Implement @ExtendedAnonInlineFunction, which requires less compile-time
      information.
"""

#= Indicates that a symbolic parameter does not have a default argument. =#
struct NoDefaultArg end

function getSignatureAsArrayFor(func::Function)::Vector
  local methodLst = collect(methods(func))
  @assert(!isempty(methodLst),
          "Invalid function passed to getSignatureAsArrayFor(). No methods found.")
  #= The full (highest-arity) method carries every positional argument name. =#
  local fullMethod = argmax(m -> m.nargs, methodLst)
  local argumentSymbols::Vector = Base.method_argnames(fullMethod)[2:end]
  local nArgumentSymbols::Int = length(argumentSymbols)
  local signatureArray::Vector = []
  #= Default values live in the lowest-arity auto-generated forwarding method,
     whose body is `self(slots..., defaults...)`. When only the full method
     exists the function has no defaults. =#
  local defaultCarrier = argmin(ci -> ci.nargs, code_lowered(func))
  if defaultCarrier.nargs == fullMethod.nargs
    for s in argumentSymbols
      push!(signatureArray, (s, NoDefaultArg()))
    end
    return signatureArray
  end
  local forwardingCall = nothing
  for st in defaultCarrier.code
    if st isa Expr && st.head === :call
      forwardingCall = st
      break
    end
  end
  @assert(forwardingCall !== nothing,
          "Could not locate the default-forwarding call in getSignatureAsArrayFor().")
  #= Skip the forwarded function/self; remaining args align with the full signature. =#
  local forwardedArgs::Vector{Any} = map(a -> resolveConstantDefault(a, defaultCarrier.code), forwardingCall.args[2:end])
  #= Only literal and constant defaults can be read back. A default that is an expression (of another argument,
     a call) is lowered into statements before the forwarding call: refuse it instead of reading a wrong value. =#
  local callee = forwardingCall.args[1]
  if !(callee isa Core.SlotNumber || callee isa Core.Argument) ||
     any(a -> a isa Core.SSAValue || a isa GlobalRef || a isa Expr, forwardedArgs)
    error("@ExtendedFunction: $(func) has a default value that is not a literal or a constant. ",
          "Supported defaults: literals (numbers, strings, symbols, true/false) and constants (nothing, const globals).")
  end
  for i = 1:nArgumentSymbols
    local val = forwardedArgs[i]
    if val isa Core.SlotNumber || val isa Core.Argument
      push!(signatureArray, (argumentSymbols[i], NoDefaultArg()))
    else
      push!(signatureArray, (argumentSymbols[i], val))
    end
  end
  signatureArray
end

#= A forwarded default that names a constant (`nothing`, a `const` global) is lowered to a statement holding the
   GlobalRef, and the argument is that statement's SSAValue: the constant's value. Anything else is returned as is. =#
function resolveConstantDefault(arg::Any, code::Vector{Any})::Any
  local ref::Any = arg isa Core.SSAValue ? code[arg.id] : arg
  if ref isa GlobalRef && isdefined(ref.mod, ref.name) && isconst(ref.mod, ref.name)
    return getglobal(ref.mod, ref.name)
  end
  return arg
end

function getNewFunctionArgs(functionToExtend, func::Function)::Vector{Tuple}
  #= These are the arguments that we want to change. =#
  functionToExtendArgs::Vector = functionToExtend.args[2:end] #= Skip function symbol. =#
  oldFunctionSig::Vector = getSignatureAsArrayFor(func)
  local functionToExtendArgsAsTuples::Vector{Tuple} = []
  for t in functionToExtendArgs
    #= Convert expr to tuple. =#
    pair = Tuple(t.args)
    @assert(size(pair, 1) >= 2, "Incorrect parameter passed to @ExtendFunction")
    push!(functionToExtendArgsAsTuples, (first(pair), last(pair)))
  end
  local numberOfArguments::Int = size(functionToExtendArgsAsTuples, 1)
  #= Create arguments for the new function.
     Generally, new functions have more symbols than the old. =#
  newArgsAsString::Vector = []
  for i = 1:numberOfArguments
    symToFind = first(functionToExtendArgsAsTuples[i])
    findFunc(x) = first(x) == symToFind
    #= Functions must have unique symbols as arguments, so this should have one index. =#
    indexOfSym = first(findall(findFunc, oldFunctionSig))
    oldFunctionSig[indexOfSym] = functionToExtendArgsAsTuples[i]
  end
  newFuncSig = oldFunctionSig
end

function tupleToKwOrSymbol(tuple::Tuple)
  sym = first(tuple)
  val = last(tuple)
  if isa(:($val), NoDefaultArg)
    sym
  else
    Expr(:kw, :($sym), :($val))
  end
end

function tupleToArgSym(tuple::Tuple)::Symbol
  sym = first(tuple)
  :($sym)
end

function getFuncFromSym(func::Symbol, __module__::Module)::Function
  getfield(__module__, func)
end

function makeFunctionHelper(functionToExtend::Expr, __module__::Module)::Tuple
  funcSym::Symbol = functionToExtend.args[1]
  func::Function = getFuncFromSym(funcSym, __module__)
  args::Vector{Tuple} = getNewFunctionArgs(functionToExtend, func)
  newFuncArgs::Tuple = Tuple(map(tupleToKwOrSymbol, args))
  argSymArr::Tuple = Tuple(map(tupleToArgSym, args))
  (func, newFuncArgs, argSymArr)
end

function makeExtendedFunction(nameOfNewFunc::Symbol, functionToExtend::Expr,
                              __module__::Module)
  (func, newFuncArgs, argSymArr) = makeFunctionHelper(functionToExtend, __module__)
  quote
    function $nameOfNewFunc($(newFuncArgs...))
      $func($(argSymArr...))
    end
  end |> esc
end

#= Creates a lambda that extends an existing function. =#
function makeExtendedLambdaFunction(functionToExtend::Expr, __module__::Module)
  (func, newFuncArgs, argSymArr) = makeFunctionHelper(functionToExtend, __module__)
  #= A lambda's optional argument is written `b = 1` in its argument tuple, not as a keyword (`:kw`) expression. =#
  local lambdaArgs::Vector{Any} = Any[a isa Expr && a.head === :kw ? Expr(:(=), a.args...) : a for a in newFuncArgs]
  Expr(:->, Expr(:tuple, lambdaArgs...), Expr(:block, :($func($(argSymArr...))))) |> esc
end

"""
    @ExtendedFunction new old(arg = value, ...)

Define `new`: the positional arguments of `old`, with new defaults for the named ones, passed on to `old`.
The Julia version of MetaModelica's `function new = old(arg = value);`, for the MetaModelica-to-Julia translator.
`old` must be defined before the macro, and its defaults must be literals or constants.
"""
macro ExtendedFunction(newFunction, functionToExtend)
  local nf::Symbol = newFunction
  local fte = functionToExtend
  makeExtendedFunction(nf, fte, __module__)
end

"""
    @ExtendedAnonFunction old(arg = value, ...)

An anonymous function: `old` with new defaults for the named arguments, as [`@ExtendedFunction`](@ref).
The Julia version of MetaModelica's `function old(arg = value)` passed as an argument.
"""
macro ExtendedAnonFunction(functionToExtend)
  local fte = functionToExtend
  makeExtendedLambdaFunction(fte, __module__)
end
