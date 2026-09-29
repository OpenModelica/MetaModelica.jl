#=
Compacted uniontypes: the variants of a uniontype folded into ONE concrete
struct with a tag field, instead of an abstract type plus one struct per
variant. Fields of that type become concrete, which is what recursive and
hot uniontypes need for inference.

The variant names stay as constructor FUNCTIONS (`CREF(...)`, `EMPTY()`), not
types. Everything that used to rely on `value isa VARIANT` goes through the
extension point `compacted_tag_info` instead:
  - `@match`/`@matchcontinue` patterns `VARIANT(...)` (see handle_destruct),
  - `isvariant(value, VARIANT)` (use it where `isa` was used),
  - `variantof(value)` (use it where `typeof` was used).

Two generators:
  - `@CUniontype`: variants form a prefix chain of fields (EMPTY(), LEAF(k, v),
    NODE(k, v, h, l, r)); variants that need fewer fields leave the trailing
    ones undefined.
  - `@T_Uniontype`: variants with disjoint fields; the struct holds the union
    of all fields and each variant fills the fields it does not use.
=#

import Accessors

"""
    compacted_tag_info(ctor) -> (StructType, tagfield::Symbol, tagvalue, fieldorder::NTuple{N,Symbol}) | nothing

Extension point for combined/tagged-union types: several conceptually distinct record
types folded into ONE concrete struct with a tag field (needed for self- or
mutually-recursive uniontype clusters, where every variant sharing one concrete type
means `@match`'s normal `isa`-based struct-pattern dispatch does not apply). A generator
targeting this representation implements one method per variant CONSTRUCTOR FUNCTION (the
value a pattern head like `ADD` evaluates to) returning
`(StructType, tagfield, tagvalue, fieldorder)`; `@match`/`@matchcontinue` then compile a
`ADD(a, b) => ...` pattern into a `getfield(obj, tagfield) === tagvalue` comparison plus
`getfield`-based destructuring of `fieldorder`, instead of `value isa ADD`. Default `nothing`
(ordinary struct-type patterns are unaffected).
"""
compacted_tag_info(::Any) = nothing

"""
    isvariant(value, variant) -> Bool

`value isa variant` that also works for compacted uniontypes. `variant` is either
a type (an ordinary `@Record`) or a constructor function registered through
`compacted_tag_info` (`@CUniontype`, `@T_Uniontype` or hand-written). For a
constructor the check is a tag comparison and constant-folds.
"""
@inline isvariant(value, variant::Type) = value isa variant
@inline function isvariant(value, variant)
  local info = compacted_tag_info(variant)
  info === nothing &&
    throw(ArgumentError("isvariant: $variant is neither a type nor a compacted uniontype constructor"))
  return value isa info[1] && getfield(value, info[2]) === info[3]
end

"""
    variantof(value)

The variant of `value`: its type for an ordinary record, its constructor
function for a compacted uniontype value. `variantof(x) === CREF` is the
compacted counterpart of `typeof(x) === CREF`.
"""
variantof(value) = typeof(value)

"""
  Resolve a pattern head (`CTOR` or a qualified `A.B.CTOR`) to its value in `mod`
  at macro-expansion time. Returns `nothing` when it does not resolve.
"""
function resolve_pattern_head(mod::Module, head)
  if head isa Symbol
    return isdefined(mod, head) ? getfield(mod, head) : nothing
  elseif head isa Expr && head.head === :. && length(head.args) == 2 && head.args[2] isa QuoteNode
    local parent = resolve_pattern_head(mod, head.args[1])
    local name = head.args[2].value
    (parent isa Module && name isa Symbol && isdefined(parent, name)) || return nothing
    return getfield(parent, name)
  end
  return nothing
end

#= Replace the uniontype's own name in a field type with the concrete struct,
   so self-references (`rest::Cref`, `body::Vector{NFStatement}`) are concrete.
   Qualified names (`A.Cref`) are left alone. =#
function _substSelfType(ex, name::Symbol, concrete::Symbol)
  ex === name && return concrete
  (ex isa Expr && ex.head !== :.) || return ex
  return Expr(ex.head, Any[_substSelfType(a, name, concrete) for a in ex.args]...)
end

#= Qualified names for the methods the generated code adds (`M.f(...) = ...`),
   so it does not depend on what the calling module has imported. =#
const _SETPROPERTIES = Expr(:., Accessors.ConstructionBase, QuoteNode(:setproperties))
const _COMPACTED_TAG_INFO = Expr(:., @__MODULE__, QuoteNode(:compacted_tag_info))
const _VARIANTOF = Expr(:., @__MODULE__, QuoteNode(:variantof))
#= metaRuntime.jl is loaded after this file; the generated code runs later. =#
const _VALUECONSTRUCTOR = Expr(:., @__MODULE__, QuoteNode(:valueConstructor))

#= Methods shared by both generators: `@match` registration per variant, the
   tag-based valueConstructor (the generic one hashes typeof, which is the same
   for every variant here) and variantof. =#
function _compacted_common_defs(structName::Symbol, variantNames::Vector{Symbol},
                                tagValues::Vector{Symbol},
                                variantFields::Vector{Vector{Symbol}})
  local defs = Expr[]
  for (vname, tagVal, fnames) in zip(variantNames, tagValues, variantFields)
    local order = Expr(:tuple, (QuoteNode(f) for f in fnames)...)
    push!(defs, :($_COMPACTED_TAG_INFO(::typeof($vname)) = ($structName, :tag, $tagVal, $order)))
  end
  push!(defs, :($_VALUECONSTRUCTOR(v::$structName) = Int(getfield(v, :tag))))
  local ctors = Expr(:tuple, variantNames...)
  push!(defs, :($_VARIANTOF(v::$structName) = $ctors[Int(getfield(v, :tag)) + 1]))
  return defs
end

"""
    @CUniontype Name begin
      VARIANT1(field1::Type1, field2::Type2, ...)
      VARIANT2(...)
      ...
    end

Declarative shorthand for the "compacted tagged struct" pattern: one concrete
`NameData <: Name` struct with a tag `@enum`, instead of `abstract type + N
records`, for self/mutually-recursive uniontype clusters. Expands to the
struct, the tag enum, one constructor function per variant (positional and
keyword forms), and the matching `compacted_tag_info` registration for each,
so `@match`/`@matchcontinue` dispatch on `VARIANT(...)` patterns exactly as
they would on ordinary struct-per-variant records. A field typed as `Name`
(the uniontype's own name) becomes `NameData`, so the recursive spine is
concrete. Nullary variants return a shared singleton.

Field layout is computed automatically: fields are collected across variants
in first-seen order, and each variant's OWN field set must equal the first K
entries of that shared order for some K (the `#undef`-via-partial-`new()`
trick used to omit fields a variant doesn't need only works when the omitted
fields are a common trailing suffix, not an arbitrary subset). This holds
naturally for variants that form a chain of increasing detail (e.g. `EMPTY()`,
`WILD()`, then `CREF(name, subscripts, rest)`); it does not hold for variants
with genuinely disjoint fields, which errors at macro-expansion time rather
than silently degrading. Use `@T_Uniontype` for those.
"""
macro CUniontype(name::Symbol, block::Expr)
  block.head === :block || error("@CUniontype: expected a `begin ... end` block of variant(field::Type, ...) declarations")
  variants = Tuple{Symbol,Vector{Tuple{Symbol,Any}}}[]
  for line in block.args
    line isa LineNumberNode && continue
    (line isa Expr && line.head === :call) || error("@CUniontype: expected `VARIANT(field::Type, ...)`, got: $line")
    vname = line.args[1]
    vname isa Symbol || error("@CUniontype: variant name must be a bare identifier, got: $vname")
    fields = Tuple{Symbol,Any}[]
    for farg in line.args[2:end]
      (farg isa Expr && farg.head === :(::) && length(farg.args) == 2) ||
        error("@CUniontype: expected `field::Type` in variant $vname, got: $farg")
      push!(fields, (farg.args[1], farg.args[2]))
    end
    push!(variants, (vname, fields))
  end
  esc(compacted_uniontype_expr(__module__, name, variants))
end

function compacted_uniontype_expr(mod::Module, name::Symbol, variants::Vector{Tuple{Symbol,Vector{Tuple{Symbol,Any}}}})
  isempty(variants) && error("@CUniontype $name: needs at least one variant")
  data_name = Symbol(name, "Data")

  field_types = Dict{Symbol,Any}()
  field_order = Symbol[]
  for (vname, fields) in variants
    for (fname, ftype) in fields
      if haskey(field_types, fname)
        field_types[fname] == ftype ||
          error("@CUniontype $name: field `$fname` used with conflicting types ($(field_types[fname]) vs $ftype) across variants")
      else
        field_types[fname] = ftype
        push!(field_order, fname)
      end
    end
  end

  #= In order: constructors and setproperties pass a variant's fields in its
     declared order to an inner constructor that takes the struct's order. =#
  for (vname, fields) in variants
    vfield_names = Symbol[f for (f, _) in fields]
    k = length(vfield_names)
    vfield_names == field_order[1:k] ||
      error("@CUniontype $name: variant `$vname`'s fields must be the first $k entries of the shared field order $(field_order), in that order; got $(vfield_names)")
  end

  tag_type = Symbol(name, "Tag")
  tag_values = [Symbol(name, "_", vname, "_TAG") for (vname, _) in variants]

  struct_fields = Any[:(tag::$tag_type)]
  for fname in field_order
    push!(struct_fields, :($fname::$(_substSelfType(field_types[fname], name, data_name))))
  end

  #= One inner constructor per distinct field count. Untyped arguments: `new`
     converts, like the default constructor (a typed List{T} argument would
     reject a concrete Cons{S}). =#
  ks = sort(unique(length(fields) for (_, fields) in variants))
  inner_ctors = Expr[]
  for k in ks
    call_args = vcat(Any[:tag], field_order[1:k])
    push!(inner_ctors, :($data_name($(call_args...)) = new($(call_args...))))
  end

  struct_def = :(struct $data_name <: $name
    $(struct_fields...)
    $(inner_ctors...)
  end)

  ctor_defs = Expr[]
  for ((vname, fields), tag_val) in zip(variants, tag_values)
    fnames = Symbol[f for (f, _) in fields]
    if isempty(fnames)
      singleton = Symbol("_", data_name, "_", vname, "_SINGLETON")
      push!(ctor_defs, :(const $singleton = $data_name($tag_val)))
      push!(ctor_defs, :($vname() = $singleton))
    else
      push!(ctor_defs, :($vname($(fnames...)) = $data_name($tag_val, $(fnames...))))
      push!(ctor_defs, :($vname(; $(fnames...)) = $vname($(fnames...))))
    end
  end
  variant_names = Symbol[v for (v, _) in variants]
  variant_fields = Vector{Symbol}[Symbol[f for (f, _) in fields] for (_, fields) in variants]
  append!(ctor_defs, _compacted_common_defs(data_name, variant_names, tag_values, variant_fields))

  #= @assign / Accessors.set: rebuild from the variant's own fields only. The
     default setproperties reads every field and fails on the #undef tail. =#
  sp_branches = Expr[]
  for ((vname, fields), tag_val) in zip(variants, tag_values)
    fnames = Tuple(f for (f, _) in fields)
    vals = [:(haskey(patch, $(QuoteNode(f))) ? getfield(patch, $(QuoteNode(f))) : getfield(obj, $(QuoteNode(f))))
            for f in fnames]
    push!(sp_branches, quote
      if getfield(obj, :tag) === $tag_val
        for k in keys(patch)
          k in $fnames || throw(ArgumentError(string("@assign: ", $(string(vname)), " has no field ", k)))
        end
        return $data_name($tag_val, $(vals...))
      end
    end)
  end
  push!(ctor_defs, quote
    function $_SETPROPERTIES(obj::$data_name, patch::NamedTuple)
      $(sp_branches...)
      error("unreachable: unknown tag")
    end
  end)

  quote
    $(isdefined(mod, name) ? nothing : :(abstract type $name end))
    @enum $tag_type $(tag_values...)
    $struct_def
    $(ctor_defs...)
  end
end

"""
    @T_Uniontype [mutable] Name begin
      VARIANT1(field1::Type1, field2::Type2 = default, ...)
      VARIANT2()
      ...
    end

Compacted uniontype for variants with DISJOINT fields (where `@CUniontype`'s
prefix rule does not hold). Expands to one concrete `NameImpl <: Name` struct
(`mutable struct` with the `mutable` flag) holding a `tag::NameTag` plus the
union of all variant fields in first-seen order, and per variant a
constructor function, a `compacted_tag_info` registration (so `@match`
patterns `VARIANT(...)` work), plus `valueConstructor` and `variantof`.
`Name` is declared as an abstract type unless it already exists (for
example through `@UniontypeDecl Name`).

Fields a variant does not have are filled with the field's default when some
variant declares one (`var::Int8 = Int8(0)`), otherwise with `nothing`; only
such a field (missing from some variant, no default) is typed
`Union{Nothing, Type}`. A field typed with the uniontype's own name is typed
as `NameImpl`.

Constructors: positional with all fields (`VARIANT(a, b, c)`), positional
with trailing defaults left out, and keyword (`VARIANT(; a, c)`) where every
defaulted field may be left out. Nullary variants of an immutable uniontype
return a shared singleton.
"""
macro T_Uniontype(args...)
  local isMutable = false
  if length(args) == 3 && args[1] === :mutable
    isMutable = true
    args = args[2:end]
  end
  length(args) == 2 || error("@T_Uniontype: expected `@T_Uniontype [mutable] Name begin ... end`")
  local name, block = args
  name isa Symbol || error("@T_Uniontype: the uniontype name must be a bare identifier, got: $name")
  (block isa Expr && block.head === :block) ||
    error("@T_Uniontype $name: expected a `begin ... end` block of VARIANT(field::Type [= default], ...) declarations")
  #= (variant name, [(field, type, has default, default)]) =#
  local variants = Tuple{Symbol,Vector{Tuple{Symbol,Any,Bool,Any}}}[]
  for line in block.args
    line isa LineNumberNode && continue
    (line isa Expr && line.head === :call) || error("@T_Uniontype $name: expected `VARIANT(field::Type, ...)`, got: $line")
    local vname = line.args[1]
    vname isa Symbol || error("@T_Uniontype $name: variant name must be a bare identifier, got: $vname")
    local fields = Tuple{Symbol,Any,Bool,Any}[]
    for farg in line.args[2:end]
      local hasDefault = false
      local default = nothing
      if farg isa Expr && farg.head === :kw
        hasDefault = true
        default = farg.args[2]
        farg = farg.args[1]
      end
      if farg isa Symbol
        push!(fields, (farg, :Any, hasDefault, default))
      elseif farg isa Expr && farg.head === :(::) && length(farg.args) == 2 && farg.args[1] isa Symbol
        push!(fields, (farg.args[1], farg.args[2], hasDefault, default))
      else
        error("@T_Uniontype $name: expected `field::Type` or `field::Type = default` in variant $vname, got: $farg")
      end
    end
    local seen = Set{Symbol}()
    for (f, _, _, _) in fields
      f in seen && error("@T_Uniontype $name: field `$f` appears twice in variant $vname")
      push!(seen, f)
    end
    push!(variants, (vname, fields))
  end
  esc(tagged_uniontype_expr(__module__, name, variants, isMutable))
end

function tagged_uniontype_expr(mod::Module, name::Symbol,
                               variants::Vector{Tuple{Symbol,Vector{Tuple{Symbol,Any,Bool,Any}}}},
                               isMutable::Bool)
  isempty(variants) && error("@T_Uniontype $name: needs at least one variant")
  local impl = Symbol(name, "Impl")
  local tagType = Symbol(name, "Tag")
  local tagValues = [Symbol(name, "_", vname, "_TAG") for (vname, _) in variants]

  #= Shared field layout: first-seen order; a field used with different types
     gets their union; the first declared default is the fill value. =#
  local fieldOrder = Symbol[]
  local fieldTypes = Dict{Symbol,Vector{Any}}()
  local fillDefault = Dict{Symbol,Any}()
  for (_, fields) in variants
    for (f, ty, hasDefault, default) in fields
      local sty = _substSelfType(ty, name, impl)
      if !haskey(fieldTypes, f)
        push!(fieldOrder, f)
        fieldTypes[f] = Any[sty]
      elseif !(sty in fieldTypes[f])
        push!(fieldTypes[f], sty)
      end
      if hasDefault && !haskey(fillDefault, f)
        fillDefault[f] = default
      end
    end
  end
  local structFields = Any[:(tag::$tagType)]
  for f in fieldOrder
    local tys = fieldTypes[f]
    local ty = length(tys) == 1 ? tys[1] : Expr(:curly, :Union, tys...)
    local inEveryVariant = all(any(vf[1] === f for vf in vfields) for (_, vfields) in variants)
    if !inEveryVariant && !haskey(fillDefault, f)
      ty = :(Union{Nothing, $ty})
    end
    push!(structFields, :($f::$ty))
  end
  local structDef = if isMutable
    :(mutable struct $impl <: $name
        $(structFields...)
      end)
  else
    :(struct $impl <: $name
        $(structFields...)
      end)
  end

  #= The value stored in struct field `f` by a variant that was given the
     arguments `given` (a variant field left out takes the variant's default). =#
  function slotValue(f::Symbol, vfields, given::Vector{Symbol})
    f in given && return f
    for (vf, _, hasDefault, default) in vfields
      vf === f && hasDefault && return default
    end
    return get(fillDefault, f, :nothing)
  end
  build(tagVal, vfields, given) = :($impl($tagVal, $((slotValue(f, vfields, given) for f in fieldOrder)...)))

  local defs = Expr[]
  for ((vname, vfields), tagVal) in zip(variants, tagValues)
    local fnames = Symbol[f for (f, _, _, _) in vfields]
    local n = length(fnames)
    if n == 0
      if isMutable
        push!(defs, :($vname() = $(build(tagVal, vfields, Symbol[]))))
      else
        local singleton = Symbol("_", impl, "_", vname, "_SINGLETON")
        push!(defs, :(const $singleton = $(build(tagVal, vfields, Symbol[]))))
        push!(defs, :($vname() = $singleton))
      end
      continue
    end
    #= Positional: all fields, plus shorter arities for trailing defaults. The
       zero-argument call is left to the keyword method below. =#
    local trailing = 0
    while trailing < n && vfields[n - trailing][3]
      trailing += 1
    end
    for arity in max(n - trailing, 1):n
      local given = fnames[1:arity]
      push!(defs, :($vname($(given...)) = $(build(tagVal, vfields, given))))
    end
    local kwargs = Any[hasDefault ? Expr(:kw, f, default) : f for (f, _, hasDefault, default) in vfields]
    push!(defs, :($vname(; $(kwargs...)) = $vname($(fnames...))))
  end
  local variantNames = Symbol[v for (v, _) in variants]
  local variantFields = Vector{Symbol}[Symbol[f for (f, _, _, _) in vfields] for (_, vfields) in variants]
  append!(defs, _compacted_common_defs(impl, variantNames, tagValues, variantFields))

  quote
    $(isdefined(mod, name) ? nothing : :(abstract type $name end))
    @enum $tagType $(tagValues...)
    $structDef
    $(defs...)
  end
end
