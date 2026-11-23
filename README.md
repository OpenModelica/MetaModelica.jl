# MetaModelica.jl [<img src="https://test.openmodelica.org/jenkins/job/MetaModelica.jl/job/master/buildStatus/icon" alt="Jenkins CI" height="20">](https://test.openmodelica.org/jenkins/job/MetaModelica.jl/job/master/) [![Tests](https://github.com/OpenModelica/MetaModelica.jl/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/OpenModelica/MetaModelica.jl/actions/workflows/test.yml) [![Coverage](https://img.shields.io/endpoint?url=https://openmodelica.github.io/MetaModelica.jl/coverage.json)](https://github.com/OpenModelica/MetaModelica.jl/actions/workflows/test.yml?query=branch%3Amaster) [![Stable Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://OpenModelica.github.io/MetaModelica.jl/stable/) [![Dev Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://OpenModelica.github.io/MetaModelica.jl/dev/) [![License: AGPL-3.0 or OSMC-PL](https://img.shields.io/badge/license-AGPL--3.0%20or%20OSMC--PL-lightgrey.svg)](LICENSE.md)

MetaModelica.jl provides Julia implementations of MetaModelica concepts used by OpenModelica: pattern matching,
uniontypes, options and immutable lists. OMFrontend.jl, the OpenModelica frontend in Julia, is written with it.

## Usage

```julia
using MetaModelica

@Uniontype Exp begin
  @Record INT begin
    value::Int
  end
  @Record ADD begin
    lhs::Exp
    rhs::Exp
  end
end

evaluate(e::Exp)::Int = @match e begin
  INT(v) => v
  ADD(l, r) => evaluate(l) + evaluate(r)
end

evaluate(ADD(INT(1), INT(2)))  # 3
```

The documentation has a page for each part:

- [Pattern matching](https://OpenModelica.github.io/MetaModelica.jl/dev/matching/): `@match`, `@matchcontinue`,
  the patterns, matching your own structs.
- [Uniontypes](https://OpenModelica.github.io/MetaModelica.jl/dev/uniontypes/): `@Uniontype`, `@Record`, and the
  compacted forms `@T_Uniontype` and `@CUniontype`.
- [Function extension](https://OpenModelica.github.io/MetaModelica.jl/dev/functionExtension/): `@ExtendedFunction`
  and `@ExtendedAnonFunction`, written for the MetaModelica-to-Julia translator.

The exported runtime builtins (`intAdd`, `stringInt`, `listHead`, `arrayGet`, ...) mimic MetaModelica's builtin
functions for code translated from MetaModelica. Pattern matching does not need them.

## Documentation

Build the documentation locally with Documenter.jl (`docs/Project.toml` uses this checkout):

```sh
julia --project=docs -e 'using Pkg; Pkg.instantiate()'
julia --project=docs docs/make.jl
```

and open `docs/build/index.html`. GitHub Actions builds the docs on pull requests, deploys `dev` from `master`
pushes, and deploys `stable` and the versioned docs at each release tag.

## Development

Run the test suite with:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

This package follows [YASGuide](https://github.com/jrevels/YASGuide).
