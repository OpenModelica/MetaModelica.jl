module ListUtilTest

using MetaModelica
import MetaModelica.ListUtil

@test list(1) == ListUtil.create(1)

@test list(1, 2) == ListUtil.create(1, 2)

@test list(1, 1, 1) == ListUtil.fill(1, 3)

@test list(3, 4, 5) == ListUtil.intRange2(3, 5)

@test_throws toOption(list(1,2,3))


end #=End List util test=#
