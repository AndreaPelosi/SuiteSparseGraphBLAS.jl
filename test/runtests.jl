using SuiteSparseGraphBLAS
using Test

SG = SuiteSparseGraphBLAS

const testdir = dirname(@__FILE__)

tests = [
    "operator",
    "matrix",
    "vector",
    "other"
]

@testset "SuiteSparseGraphBLAS" begin
    for t in tests
        tp = joinpath(testdir, "$(t).jl")
        include(tp)
    end
end
