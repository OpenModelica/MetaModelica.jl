module ListUtilTest

using MetaModelica
import MetaModelica.ListUtil
using ListUtil

@test list(1) == create(1)

@test list(1, 2) == create(1, 2)

@test list(1, 1, 1) == fill(1, 3)

@test list(3, 4, 5) == intRange2(3, 5)

@test_throws toOption(list(1,2,3))

@test intRange3(3, 2, 9) == list(3, 5, 7, 9)

@test fromOption(NONE()) == list()

try
  @test assertIsEmtpy(list())
  true
catch
  false
end

@test isEqual(list(1, 2, 3), list(1, 2, 3))

isEqual = (x, y) -> x == y
@test isEqualOnTrue(list(1, 2, 3), list(1, 2, 3), isEqual)

@test isPrefixOnTrue(list(1, 2 , 3), list(1, 2, 3, 4))

@test consr(list(2), 1) == list(2, 1)

@test append_reverse(list(1,2,3), list()) == list(3, 2, 1)

f = (x) -> x == 1
@test !ListUtil.all(list(1:100..., f)

@test listIsLonger(list(1,2,3), list(1,2))

@test sort(list(1,2,3,4,,5,6,7), intGt)
                    
@test insert({2,1,4,2},2,3) == list(2, 3, 1 4, 2)

@test intersectionOnTrue({1, 4, 2}, {5, 2, 4, 6}, intEq) == list(4, 2)

@test(listArrayReverse(list(1,2,3)) == [1,2,3])

@test split(list(1,2,5,7), 2) == (list(2, 1) list(5, 7))                    
                    
end #=End List util test=#
