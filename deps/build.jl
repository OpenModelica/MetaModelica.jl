@info("MetaModelica: Starting build script")

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
