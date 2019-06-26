#= 
  Implementation of function inheritance. E.g functions extending other functions
  @ExtendFunction pathStringNoQual pathString(usefq=false)

  This means defining a new function pathStringNoQual equal to pathString. However, 
  the usefq argument now has a different default value.

  We do so by creating a new function but passing the redefined arguments to it.
  
=#


#= 
function foo(a,b=1,c=2) end 
methods(foo)
# 3 methods for generic function "foo":
[1] foo(a) in Main at REPL[8]:1
[2] foo(a, b) in Main at REPL[8]:1
[3] foo(a, b, c) in Main at REPL[8]:1

Note:
@ExtendFunction foo newFoo(a = 1, c = 2)

That would result in the following call:

function newFoo(a=1)
  foo(a)
end

Analogously:
@ExtendFunction newFoo(a = 1, b = 2, c = 3)

function newFoo(a = 1, b = 2, c = 3)
  foo(a,b,c)
end 
=#

using MacroTools

function pathString(usefq=true)
    usefq
end

function getSignatureAsArrayFor(func::Function)
    methodLst = methods(func)
    sizeOfLeastGenericSignature = size(methodLst.ms, 1)
    @assert(sizeOfLeastGenericSignature >= 1,
            "Invalid function passed to getSignatureAsArrayFor(). Size was: $(sizeOfLeastGenericSignature)")
    typeSignature::Array = methodLst.ms[sizeOfLeastGenericSignature].sig.parameters |> collect
    argumentSymbols::Array = Base.method_argnames(methodLst.ms[sizeOfLeastGenericSignature])[2:end]
    #= Creates an array with the max(positional arguments) =#
    defaultValues = code_lowered(func)[1].code[1].args[2:end]
    #= Construct an array consisting of (Symbol, defaultValue if it exists otherwise nothing, the type for the argument) =#
    local signatureArray::Array = []
    for i in 1:size(argumentSymbols,1)
        #= If no default value is present we add nothing instead place =#
        if typeof(defaultValues[i]) == Core.SlotNumber
            push!(signatureArray, (argumentSymbols[i], nothing, typeSignature[i]))
        else
            push!(signatureArray, (argumentSymbols[i], defaultValues[i], typeSignature[i]))
        end
    end
    signatureArray
end

function getNewFunctionArgs(functionToExtend, func::Function)
    #= These are the arguments that we would like to change =#
    functionToExtendArgs = functionToExtend.args[2]
    oldFunctionSig = getSignatureAsArrayFor(func)
    functionToExtendArgsAsArray = [i for i in functionToExtendArgs.args]
    local functionToExtendArgsAsTuple::Array = []
    for i in 2:2:size(functionToExtendArgsAsArray, 1)
        push!(functionToExtendArgsAsTuple, (functionToExtendArgsAsArray[i-1], functionToExtendArgsAsArray[i]))
    end
    local numberOfArguments::Integer = size(functionToExtendArgsAsTuple, 1)
    #= Create arguments for the new function. Generally the new functions have more symbols then the old =#
    newArgsAsString::Array = []
    for i in 1:numberOfArguments
        symToFind = first(functionToExtendArgsAsTuple[i])
        findFunc(x) = first(x) == symToFind 
        #= We will get an array with one index! Functions must have unique symbols as arguments=#
        indexOfSym = first(findall(findFunc, oldFunctionSig))
        oldFunctionSig[indexOfSym] = functionToExtendArgsAsTuple[i]
    end
    newFuncSig = oldFunctionSig
end

function getNewFunctionBody(functionToExtend)
    functionName = functionToExtend.args[1]
    quote @expand $functionName end
end

#= Converts a tuple consisting of an argument value pair into a kw expression=#
function tupleToKw(tuple::Tuple)::Expr
    sym = first(tuple)
    val = last(tuple)
    :(kw, $sym, $val)
end

function tupleToArgSym(tuple::Tuple)::Symbol
    sym = first(tuple)
    :($sym)
end

#= 
  TODO: To make extend work across module the scope must also be extracted and passed here at some later stage 
=#
function getFuncFromSym(func::Symbol)::Function
    scope = @__MODULE__
    getproperty(scope, func)
end

function makeExtendedFunction(nameOfNewFunc::Symbol, functionToExtend::Expr)
  sym = functionToExtend.args[1]
  func = getFuncFromSym(sym)
  args = getNewFunctionArgs(functionToExtend, func)
  newFuncArgs = Expr((args |> x -> tupleToKw(first(x)).args)...,)
  argSymArr = args |> x -> tupleToArgSym(first(x))
  quote
      function $nameOfNewFunc($(newFuncArgs))
          $func($argSymArr)
      end
  end |> esc
end

macro ExtendFunction(newFunction, functionToExtend)
    makeExtendedFunction(:($newFunction), functionToExtend)
end

println(@macroexpand @ExtendFunction pathStringNoQual pathString(usefq=false))

@ExtendFunction pathStringNoQual pathString(usefq=false)
