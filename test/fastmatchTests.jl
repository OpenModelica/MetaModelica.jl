module FastMatchTests

using MetaModelica
using Test

#= Each @fastmatch call defines `<value-symbol>Func` at module scope. =#
#= We use distinct value names so the test cases do not extend the same =#
#= dispatch table and overwrite each other. =#

struct FA; v::Int end
struct FB; l::Int; r::Int end
struct FC end

@testset "Positional bindings (single field)" begin
  classify_a(fm_a) = @fastmatch fm_a begin
    FA(v) => v + 1
    FB(l, r) => l + r
    FC()  => 0
  end
  @test classify_a(FA(10)) == 11
  @test classify_a(FB(3, 4)) == 7
  @test classify_a(FC()) == 0
end

@testset "Wildcard placeholders skip fields" begin
  pickFirst(fm_b) = @fastmatch fm_b begin
    FB(l, _) => l
    FA(v) => v
    FC()  => -1
  end
  @test pickFirst(FB(7, 99)) == 7
  @test pickFirst(FA(5))     == 5
  @test pickFirst(FC())      == -1

  pickSecond(fm_c) = @fastmatch fm_c begin
    FB(_, r) => r
    FA(_) => 0
    FC()  => 0
  end
  @test pickSecond(FB(7, 99)) == 99
end

@testset "All-wildcard `__` pattern matches without binding" begin
  saySomething(fm_d) = @fastmatch fm_d begin
    FA(__) => :saw_a
    FB(__) => :saw_b
    FC()   => :saw_c
  end
  @test saySomething(FA(1))   === :saw_a
  @test saySomething(FB(1,2)) === :saw_b
  @test saySomething(FC())    === :saw_c
end

@testset "Keyword bindings" begin
  kwGet(fm_e) = @fastmatch fm_e begin
    FA(v=x)        => x * 10
    FB(l=lhs, r=_) => lhs
    FC()           => 0
  end
  @test kwGet(FA(3))   == 30
  @test kwGet(FB(5,9)) == 5
  @test kwGet(FC())   == 0
end

@testset "Empty constructor" begin
  isEmpty(fm_f) = @fastmatch fm_f begin
    FC()    => true
    FA(__)  => false
    FB(__)  => false
  end
  @test isEmpty(FC())
  @test !isEmpty(FA(1))
  @test !isEmpty(FB(1,2))
end

@testset "No allocations on the fast path" begin
  classify_alloc(fm_g) = @fastmatch fm_g begin
    FA(v)    => v + 1
    FB(l, r) => l + r
    FC()     => 0
  end

  function loop(values)
    s = 0
    for v in values
      s += classify_alloc(v)
    end
    s
  end

  values = Any[FA(1), FB(2, 3), FC(), FA(4), FB(5, 6), FC(),
               FA(7), FB(8, 9), FC(), FA(10), FB(11, 12)]

  loop(values)  #= warm up =#
  bytes = @allocated loop(values)
  #= With the rewrite, each method dispatches directly and returns Int. =#
  #= Allocations should come only from boxing the Any input vector iteration, =#
  #= not from the @fastmatch body. We assert a tight bound. =#
  @test bytes < 1024
end

@testset "Errors on unsupported patterns" begin
  #= Literal field pattern is not supported and should error at expansion. =#
  ex_literal = quote
    function badLiteral(fm_x)
      @fastmatch fm_x begin
        FA(1) => :one
      end
    end
  end
  @test_throws Exception eval(ex_literal)

  #= Bare wildcard `_ => ...` is not allowed since pattern must be a call. =#
  ex_wild = quote
    function badWildcard(fm_y)
      @fastmatch fm_y begin
        _ => :nope
      end
    end
  end
  @test_throws Exception eval(ex_wild)

  #= Non-Symbol value is rejected. =#
  ex_value = quote
    @fastmatch (1+1) begin
      FA(v) => v
    end
  end
  @test_throws Exception eval(ex_value)

  #= Duplicate case head is rejected. =#
  ex_dup = quote
    function badDup(fm_dup)
      @fastmatch fm_dup begin
        FA(v) => v
        FA(w) => w + 1
      end
    end
  end
  @test_throws Exception eval(ex_dup)

  #= Non-uniform return types are rejected. =#
  ex_nonuniform = quote
    function badReturn(fm_ret)
      @fastmatch fm_ret begin
        FA(v)    => v             #= Int =#
        FB(l, r) => string(l, r)  #= String =#
      end
    end
  end
  @test_throws Exception eval(ex_nonuniform)
end

end #= End FastMatchTests =#
