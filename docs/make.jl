using Documenter
using MetaModelica

makedocs(
  sitename = "MetaModelica.jl",
  modules = [
    MetaModelica,
    MetaModelica.UniontypeDef,
    MetaModelica.Dangerous,
  ],
  format = Documenter.HTML(
    prettyurls = get(ENV, "CI", "false") == "true",
  ),
  pages = [
    "Home" => "index.md",
    "API Reference" => "api.md",
  ],
)

deploydocs(
  repo = "github.com/OpenModelica/MetaModelica.jl.git",
  devbranch = "master",
)
