@info("MetaModelica: Starting build script")
push!(LOAD_PATH, "@v#.#", "@stdlib")
using Pkg

# Add dependencies
function buildDeps()
  Pkg.add("DataStructures")
  Pkg.add("MacroTools")
  Pkg.add("ImmutableList")
  @info("Build all dependencies succesfull")
end

buildDeps()
@info("MetaModelica: Finished build script")
