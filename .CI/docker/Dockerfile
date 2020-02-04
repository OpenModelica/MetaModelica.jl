FROM julia:1.2.0

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        autoconf \
        build-essential \
        git \
        mc \
        nano \
        curl \
        wget \
        gpg \
  && \

RUN export HOME=/home/julia && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add Compat  ;precompile");using Compat' && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add DataFrames;precompile");using DataFrames' && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add DataStructures  ;precompile");using DataStructures' && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add LightXML  ;precompile");using LightXML' && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add Random  ;precompile");using Random' && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add Test  ;precompile");using Test' && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add https://github.com/OpenModelica/ImmutableList.jl  ;precompile"); using ImmutableList' && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add ExportAll  ;precompile");using ExportAll' && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add MacroTools   ;precompile");using MacroTools' && \
    julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add https://github.com/OpenModelica/MetaModelica.jl   ;precompile"); using MetaModelica' && \
    (cd /home/julia && tar cf /home/julia.tar .julia) && rm -rf /home/julia/.julia && chmod ugo+rwx /home/julia
