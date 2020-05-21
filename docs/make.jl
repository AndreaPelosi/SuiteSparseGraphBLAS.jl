using Documenter, SuiteSparseGraphBLAS

makedocs(
    modules     = [SuiteSparseGraphBLAS],
    format      = Documenter.HTML(),
    sitename    = "SuiteSparseGraphBLAS",
    doctest     = false,
    pages       = Any[
		"Home"								=> "index.md",
		"Matrix operations"					=> "matrix.md",
    ]
)

deploydocs(
    target = "build",
    deps   = nothing,
    make   = nothing,
    repo   = "https://github.com/cvdlab/SuiteSparseGraphBLAS.jl"
)
