@testset "with macro" begin

    # one operator

    @test SG.g_operators.semiring === Semirings.PLUS_TIMES
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], [1,2,3,4])
    B = copy(A)
    res1 = SG.mxm(A, B)
    SG.@with Semirings.TIMES_PLUS begin
        res2 = SG.mxm(A, B)
    end
    res3 = SG.mxm(A, B)

    @test SG.g_operators.semiring === Semirings.PLUS_TIMES
    @test res1[1,1] == 7 && res1[1,2] == 10 && res1[2,1] == 15 && res1[2,2] == 22
    @test res2[1,1] == 10 && res2[1,2] == 18 && res2[2,1] == 28 && res2[2,2] == 40
    @test res3[1,1] == 7 && res3[1,2] == 10 && res3[2,1] == 15 && res3[2,2] == 22

    
    # two operator
    @test SG.g_operators.semiring === Semirings.PLUS_TIMES
    @test SG.g_operators.monoid === Monoids.PLUS
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], [2,3,4,5])
    B = copy(A)

    SG.@with Semirings.TIMES_PLUS, Monoids.TIMES begin
        res = SG.mxm(A, B)
        red = SG.reduce_scalar(A)
    end

    @test SG.g_operators.semiring === Semirings.PLUS_TIMES
    @test SG.g_operators.monoid === Monoids.PLUS

    @test res[1,1] == 28 && res[1,2] == 40 && res[2,1] == 54 && res[2,2] == 70
    @test red == 120


end