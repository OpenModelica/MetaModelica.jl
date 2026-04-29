# MetaModelica.jl [![Jenkins CI](https://test.openmodelica.org/jenkins/job/MetaModelica.jl/job/master/badge/icon)](https://test.openmodelica.org/jenkins/job/MetaModelica.jl/job/master/) [![Stable Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://OpenModelica.github.io/MetaModelica.jl/stable/) [![Dev Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://OpenModelica.github.io/MetaModelica.jl/dev/) [![License: OSMC-PL](https://img.shields.io/badge/license-OSMC--PL-lightgrey.svg)](LICENSE.md)

MetaModelica.jl provides Julia implementations of MetaModelica runtime concepts used by OpenModelica, including pattern matching macros, union and record helpers, optional values, immutable-list integration, and runtime compatibility functions.

## Usage

```julia
using MetaModelica

value = @match (1, 2) begin
  (x, y) => x + y
end
```

The main entry points are `@match`, `@matchcontinue`, `@Uniontype`, `@Record`, `SOME`, `NONE`, and the exported MetaModelica runtime helper functions.

## Documentation

Documentation is generated with Documenter.jl:

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(path=pwd()); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

GitHub Actions builds the docs on pull requests and deploys them from `master` pushes.

## Development

Run the test suite with:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

This package follows [YASGuide](https://github.com/jrevels/YASGuide).
