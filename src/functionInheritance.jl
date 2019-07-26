#= 
  Implementation of function inheritance. E.g enabling functions to extend other functions
  @ExtendedFunction pathStringNoQual pathString(usefq=false)

  This means defining a new function pathStringNoQual equal to pathString. However, 
  the usefq argument now has a different default value.

  We do so by creating a new function but passing the redefined arguments to it.

  It is also possible to define an anonymous function using the following syntax:
 
  @ExtendedAnonFunction pathString(usefq=false)
 
  The later defines a lambda function that extends pathString. However, the default values of the 
  parameters can be changed MetaModelica style.

@Author John Tinnerholm, same license as the rest of this package

TODO: Note that ExtendedAnonFunction does not work for inline expressions 
      Same with @ExtendedFunction. The reason being that certain variables will not be in use by 
      then.
      Implement @ExtendedAnonInlineFunction, which does the same but requires less available compile time 
      information.  
=#

#= Used to indicate that a specific symbolic parameter does not have a default argument =#
struct NoDefaultArg end

function getSignatureAsArrayFor(func::Function)::Array
  methodLst = methods(func)
  sizeOfLeastGenericSignature = size(methodLst.ms, 1)
  @assert(sizeOfLeastGenericSignature >= 1,
          "Invalid function passed to getSignatureAsArrayFor(). Size was: $(sizeOfLeastGenericSignature)")
  argumentSymbols::Array = Base.method_argnames(methodLst.ms[sizeOfLeastGenericSignature])[2:end]
  #= Creates an array with the max(positional arguments) =#
  defaultValues = code_lowered(func)[1].code[1].args[2:end]
  #= Construct an array consisting of (Symbol, defaultValue if it exists otherwise nothing, the type for the argument) =#
  local signatureArray::Array = []
  local nDefaultValues::Integer = size(defaultValues, 1)
  local nArgumentSymbols::Integer = size(argumentSymbols, 1)
  for i in 1:nArgumentSymbols
    #= 
      If no default value is present. We add nothing instead place.
      This case occurs if i is larger then the ammount of default values.
      However, sometimes Core.SlotNumber occurs other times it does not.
    =#
    if i > nDefaultValues
      push!(signatureArray, (argumentSymbols[i], NoDefaultArg()))
    elseif typeof(defaultValues[i]) == Core.SlotNumber
      push!(signatureArray, (argumentSymbols[i], NoDefaultArg()))
    else
      push!(signatureArray, (argumentSymbols[i], defaultValues[i]))
    end
  end
  signatureArray
end

function getNewFunctionArgs(functionToExtend, func::Function)::Array{Tuple}
  #= These are the arguments that we would like to change =#
  functionToExtendArgs::Array = functionToExtend.args[2:end] #Skipping function symbol
  oldFunctionSig::Array = getSignatureAsArrayFor(func)
  local functionToExtendArgsAsTuples::Array{Tuple} = []
  for t in functionToExtendArgs
    #Convert expr to tuple
    pair = Tuple(t.args)
    @assert(size(pair, 1) >= 2, "Incorrect parameter passed to @ExtendFunction")
    push!(functionToExtendArgsAsTuples, (first(pair), last(pair)))
    end
  local numberOfArguments::Integer = size(functionToExtendArgsAsTuples, 1)
  #= Create arguments for the new function. 
     Generally the new functions have more symbols then the old =#
  newArgsAsString::Array = []
  for i in 1:numberOfArguments
      symToFind = first(functionToExtendArgsAsTuples[i])
      findFunc(x) = first(x) == symToFind 
      #= We will get an array with one index! Functions must have unique symbols as arguments=#
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
  args::Array{Tuple} = getNewFunctionArgs(functionToExtend, func)
  newFuncArgs::Tuple = Tuple(map(tupleToKwOrSymbol, args))
  argSymArr::Tuple = Tuple(map(tupleToArgSym, args))
  (func, newFuncArgs, argSymArr)
end

function makeExtendedFunction(nameOfNewFunc::Symbol, functionToExtend::Expr, __module__::Module)
  (func, newFuncArgs, argSymArr) = makeFunctionHelper(functionToExtend, __module__)
  quote
    function $nameOfNewFunc($(newFuncArgs...))
      $func($(argSymArr...))
    end 
  end |> esc
end

#= Creates a lambda that extends an existing function =#
function makeExtendedLambdaFunction(functionToExtend::Expr, __module__::Module)
  (func, newFuncArgs, argSymArr) = makeFunctionHelper(functionToExtend, __module__)
  if size(newFuncArgs,1) == 0
    :(() -> $func($(argSymArr...))) |> esc
  else
    quote
      $((newFuncArgs...)) -> $func($(argSymArr...))
    end |> esc
  end
end

macro ExtendedFunction(newFunction, functionToExtend)
  local nf::Symbol = newFunction
  local fte = functionToExtend
  makeExtendedFunction(nf, fte, __module__)
end |> esc

macro ExtendedAnonFunction(functionToExtend)
  local fte = functionToExtend
  makeExtendedLambdaFunction(fte, __module__)
end |> esc
