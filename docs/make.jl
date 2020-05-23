push!(LOAD_PATH,"../src/")

using Documenter, SuiteSparseGraphBLAS

makedocs(
    modules     = [SuiteSparseGraphBLAS],
    format      = Documenter.HTML(),
    sitename    = "SuiteSparseGraphBLAS",
    doctest     = false,
    pages       = Any[
		"Home"								=> "index.md",
    "Matrix operations"					=> "matrix.md",
    "Vector operations"					=> "vector.md",
    "Operators"                 => "operator.md"
    ]
)

deploydocs(
    repo = "github.com/cvdlab/SuiteSparseGraphBLAS.jl.git",
)
