using SuiteSparseGraphBLAS
using Test

SG = SuiteSparseGraphBLAS

SG.GrB_init(0)

const testdir = dirname(@__FILE__)

tests = [
    "operator",
    "matrix",
    "vector"
]

@testset "SuiteSparseGraphBLAS" begin
    for t in tests
        tp = joinpath(testdir, "$(t).jl")
        include(tp)
    end
end
