using Documenter
using MetaModelica

makedocs(
  sitename = "MetaModelica.jl",
  modules = [
    MetaModelica,
    MetaModelica.UniontypeDef,
    MetaModelica.Dangerous,
    MetaModelica.MM_Debug,
  ],
  format = Documenter.HTML(
    prettyurls = get(ENV, "CI", "false") == "true",
  ),
  pages = [
    "Home" => "index.md",
    "Pattern matching" => "matching.md",
    "Uniontypes" => "uniontypes.md",
    "Function extension" => "functionExtension.md",
    "API Reference" => "api.md",
  ],
)

deploydocs(
  repo = "github.com/OpenModelica/MetaModelica.jl.git",
  devbranch = "master",
)
