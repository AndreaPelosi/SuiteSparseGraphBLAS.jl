@testset "with macro" begin

    # one operator

    @test SG.g_operators.semiring === Semirings.PLUS_TIMES
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], [1,2,3,4])
    B = copy(A)
    res1 = SG.mxm(A, B)
    SG.@with Semirings.TIMES_PLUS begin
        res2 = SG.mxm(A, B)
    end
    res3 = SG.mxm(A, B)

    @test SG.g_operators.semiring === Semirings.PLUS_TIMES
    @test res1[0,0] == 7 && res1[0,1] == 10 && res1[1,0] == 15 && res1[1,1] == 22
    @test res2[0,0] == 10 && res2[0,1] == 18 && res2[1,0] == 28 && res2[1,1] == 40
    @test res3[0,0] == 7 && res3[0,1] == 10 && res3[1,0] == 15 && res3[1,1] == 22

    
    # two operator
    @test SG.g_operators.semiring === Semirings.PLUS_TIMES
    @test SG.g_operators.monoid === Monoids.PLUS
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], [1,2,3,4])
    B = copy(A)

    SG.@with Semirings.TIMES_PLUS, Monoids.TIMES begin
        res = SG.mxm(A, B)
        red = SG.reduce_scalar(A)
    end

    @test SG.g_operators.semiring === Semirings.PLUS_TIMES
    @test SG.g_operators.monoid === Monoids.PLUS

    @test res[0,0] == 10 && res[0,1] == 18 && res[1,0] == 28 && res[1,1] == 40
    @test red == 24


end