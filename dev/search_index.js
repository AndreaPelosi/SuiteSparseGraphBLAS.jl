var documenterSearchIndex = {"docs":
[{"location":"matrix/#","page":"Matrix operations","title":"Matrix operations","text":"from_type(::DataType, ::Int64, ::Int64)\nfrom_lists(::Vector, ::Vector, ::Vector)\nfrom_matrix\nidentity\nMatrix(::GBMatrix)\nsquare\nsize(::GBMatrix)\nfindnz(::GBMatrix)\n==(::GBMatrix, ::GBMatrix)\nnnz(::GBMatrix)\nclear!(::GBMatrix)\ncopy(::GBMatrix)\nlastindex(::GBMatrix)\nmxm\nmxv\nemult(::GBMatrix, ::GBMatrix)\neadd(::GBMatrix, ::GBMatrix)\napply(::GBMatrix)\napply!(::GBMatrix)\nselect(::GBMatrix, ::SelectOperator)\nreduce_vector\nreduce_scalar\ntranspose\nkron","category":"page"},{"location":"matrix/#SuiteSparseGraphBLAS.from_type-Tuple{DataType,Int64,Int64}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.from_type","text":"from_type(type, m, n)\n\nCreate an empty GBMatrix of size m×n from the given type type.\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.from_lists-Tuple{Array{T,1} where T,Array{T,1} where T,Array{T,1} where T}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.from_lists","text":"from_lists(I, J, V; m = nothing, n = nothing, type = nothing, combine = Binaryop.FIRST)\n\nCreate a new GBMatrix from the given lists of row indices, column indices and values. If m and n are not provided, they are computed from the max values of the row and column indices lists, respectively. If type is not provided, it is inferred from the values list. A combiner Binary Operator can be provided to manage duplicates values. If it is not provided, the default BinaryOp.FIRST is used.\n\nArguments\n\nI: the list of row indices.\nJ: the list of column indices.\nV: the list of values.\n[m]: the number of rows.\n[n]: the number of columns.\n[type]: the type of the elements of the matrix.\n[combine]: the BinaryOperator which assembles any duplicate entries with identical indices.\n\nExamples\n\njulia> from_lists([1,1,2,3], [1,2,2,2], [5,2,7,4])\n3x2 GBMatrix{Int64} with 4 stored entries:\n  [1, 1] = 5\n  [1, 2] = 2\n  [2, 2] = 7\n  [3, 2] = 4\n\njulia> from_lists([1,1,2,3], [1,2,2,2], [5,2,7,4], type=Float64)\n3x2 GBMatrix{Float64} with 4 stored entries:\n  [1, 1] = 5.0\n  [1, 2] = 2.0\n  [2, 2] = 7.0\n  [3, 2] = 4.0\n\njulia> from_lists([1,1,2,3], [1,2,2,2], [5,2,7,4], m=10, n=4)\n10x4 GBMatrix{Int64} with 4 stored entries:\n  [1, 1] = 5\n  [1, 2] = 2\n  [2, 2] = 7\n  [3, 2] = 4\n\njulia> A = from_lists([1,1,2,3], [1,1,2,2], [5,2,7,4], combine=Binaryop.PLUS)\n3x2 GBMatrix{Int64} with 3 stored entries:\n  [1, 1] = 7\n  [2, 2] = 7\n  [3, 2] = 4\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.from_matrix","page":"Matrix operations","title":"SuiteSparseGraphBLAS.from_matrix","text":"from_matrix(m)\n\nCreate a GBMatrix from the given Matrix m.\n\nExamples\n\njulia> from_matrix([1 0 2; 0 0 3; 0 1 0])\n3x3 GBMatrix{Int64} with 4 stored entries:\n  [1, 1] = 1\n  [1, 3] = 2\n  [2, 3] = 3\n  [3, 2] = 1\n\n\n\n\n\n","category":"function"},{"location":"matrix/#Base.identity","page":"Matrix operations","title":"Base.identity","text":"identity(type, n)\n\nCreate an identity GBMatrix of size n×n with the given type type.\n\nExamples\n\njulia> identity(Bool, 4)\n4x4 GBMatrix{Bool} with 4 stored entries:\n  [1, 1] = true\n  [2, 2] = true\n  [3, 3] = true\n  [4, 4] = true\n\n\n\n\n\n","category":"function"},{"location":"matrix/#Base.Matrix-Tuple{GBMatrix}","page":"Matrix operations","title":"Base.Matrix","text":"Matrix(A::GBMatrix{T}) -> Matrix{T}\n\nConstruct a Matrix{T} from a GBMatrix{T} A.\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.square","page":"Matrix operations","title":"SuiteSparseGraphBLAS.square","text":"square(m::GBMatrix)\n\nReturn true if m is a square matrix.\n\nExamples\n\njulia> A = from_matrix([1 2; 4 5]);\n\njulia> square(A)\ntrue\n\n\n\n\n\n","category":"function"},{"location":"matrix/#Base.size-Tuple{GBMatrix}","page":"Matrix operations","title":"Base.size","text":"size(m::GBMatrix, [dim])\n\nReturn a tuple containing the dimensions of m. Optionally you can specify a dimension to just get the length of that dimension.\n\nExamples\n\njulia> A = from_matrix([1 2 3; 4 5 6]);\n\njulia> size(A)\n(2, 3)\n\njulia> size(A, 1)\n2\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.findnz-Tuple{GBMatrix}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.findnz","text":"findnz(m::GBMatrix)\n\nReturn a tuple (I, J, V) where I and J are the row and column lists of the \"non-zero\" values in m, and V is a list of \"non-zero\" values.\n\nExamples\n\njulia> A = from_matrix([1 2 0; 0 0 1]);\n\njulia> findnz(A)\n([1, 1, 2], [1, 2, 3], [1, 2, 1])\n\n\n\n\n\n","category":"method"},{"location":"matrix/#Base.:==-Tuple{GBMatrix,GBMatrix}","page":"Matrix operations","title":"Base.:==","text":"==(A, B)\n\nCheck if two matrices A and B are equal.\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.nnz-Tuple{GBMatrix}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.nnz","text":"nnz(m::GBMatrix)\n\nReturn the number of entries in a matrix m.\n\nExamples\n\njulia> A = from_matrix([1 2 0; 0 0 1]);\n\njulia> nnz(A)\n3\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.clear!-Tuple{GBMatrix}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.clear!","text":"clear!(m::GBMatrix)\n\nClear all entries from a matrix m.\n\n\n\n\n\n","category":"method"},{"location":"matrix/#Base.copy-Tuple{GBMatrix}","page":"Matrix operations","title":"Base.copy","text":"copy(v::GBVector)\n\nCreate a copy of v.\n\nExamples\n\njulia> v = from_vector([1, 0, 0, 1, 2, 0]);\n\njulia> u = copy(v)\n6-element GBVector{Int64} with 3 stored entries:\n  [1] = 1\n  [4] = 1\n  [5] = 2\n\njulia> u == v\ntrue\n\njulia> u === v\nfalse\n\n\n\n\n\ncopy(m::GBMatrix)\n\nCreate a copy of m.\n\nExamples\n\njulia> A = from_matrix([1 0 1; 0 0 2; 2 0 1]);\n\njulia> B = copy(A)\n3x3 GBMatrix{Int64} with 5 stored entries:\n  [1, 1] = 1\n  [1, 3] = 1\n  [2, 3] = 2\n  [3, 1] = 2\n  [3, 3] = 1\n\njulia> A == B\ntrue\n\njulia> A === B\nfalse\n\n\n\n\n\n","category":"method"},{"location":"matrix/#Base.lastindex-Tuple{GBMatrix}","page":"Matrix operations","title":"Base.lastindex","text":"lastindex(m::GBMatrix, [d])\n\nReturn the last index of a matrix m. If d is given, return the last index of m along dimension d.\n\nExamples\n\njulia> A = from_matrix([1 2 0; 0 0 1]);\n\njulia> lastindex(A)\n(2, 3)\n\njulia> lastindex(A, 2)\n3\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.mxm","page":"Matrix operations","title":"SuiteSparseGraphBLAS.mxm","text":"mxm(A::GBMatrix, B::GBMatrix; kwargs...)\n\nMultiply two sparse matrix A and B using the semiring. If a semiring is not provided, it uses the default semiring.\n\nArguments\n\nA: the first matrix.\nB: the second matrix.\n[out]: the output matrix for result.\n[semiring]: the semiring to use.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask, A and B.\n\nExamples\n\njulia> A = from_matrix([1 2; 3 4]);\n\njulia> B = copy(A);\n\njulia> mxm(A, B, semiring = Semirings.PLUS_TIMES)\n2x2 GBMatrix{Int64} with 4 stored entries:\n  [1, 1] = 7\n  [1, 2] = 10\n  [2, 1] = 15\n  [2, 2] = 22\n\n\n\n\n\n","category":"function"},{"location":"matrix/#SuiteSparseGraphBLAS.mxv","page":"Matrix operations","title":"SuiteSparseGraphBLAS.mxv","text":"mxv(A::GBMatrix, u::GBVector; kwargs...) -> GBVector\n\nMultiply a sparse matrix A times a column vector u.\n\nArguments\n\nA: the sparse matrix.\nu: the column vector.\n[out]: the output vector for result.\n[semiring]: the semiring to use.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask, A and B.\n\nExamples\n\njulia> A = from_matrix([1 2; 3 4]);\n\njulia> u = from_vector([1, 2]);\n\njulia> mxv(A, u, semiring = Semirings.PLUS_TIMES)\n2-element GBVector{Int64} with 2 stored entries:\n  [1] = 5\n  [2] = 11\n\n\n\n\n\n","category":"function"},{"location":"matrix/#SuiteSparseGraphBLAS.emult-Tuple{GBMatrix,GBMatrix}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.emult","text":"emult(A::GBMatrix, B::GBMatrix; kwargs...)\n\nCompute the element-wise \"multiplication\" of two matrices A and B, using a Binary Operator, a Monoid or a Semiring. If given a Monoid, the additive operator of the monoid is used as the multiply binary operator. If given a Semiring, the multiply operator of the semiring is used as the multiply binary operator.\n\nArguments\n\nA: the first matrix.\nB: the second matrix.\n[out]: the output matrix for result.\n[operator]: the operator to use. Can be either a Binary Operator, or a Monoid or a Semiring.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask, A and B.\n\nExamples\n\njulia> A = from_matrix([1 2; 3 4]);\n\njulia> B = copy(A);\n\njulia> emult(A, B, operator = Binaryop.PLUS)\n2x2 GBMatrix{Int64} with 4 stored entries:\n  [1, 1] = 2\n  [1, 2] = 4\n  [2, 1] = 6\n  [2, 2] = 8\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.eadd-Tuple{GBMatrix,GBMatrix}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.eadd","text":"eadd(A::GBMatrix, B::GBMatrix; kwargs...)\n\nCompute the element-wise \"addition\" of two matrices A and B, using a Binary Operator, a Monoid or a Semiring. If given a Monoid, the additive operator of the monoid is used as the add binary operator. If given a Semiring, the additive operator of the semiring is used as the add binary operator.\n\nArguments\n\nA: the first matrix.\nB: the second matrix.\n[out]: the output matrix for result.\n[operator]: the operator to use. Can be either a Binary Operator, or a Monoid or a Semiring.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask, A and B.\n\nExamples\n\njulia> A = from_matrix([1 2; 3 4]);\n\njulia> B = copy(A);\n\njulia> eadd(A, B, operator = Binaryop.TIMES)\n2x2 GBMatrix{Int64} with 4 stored entries:\n  [1, 1] = 1\n  [1, 2] = 4\n  [2, 1] = 9\n  [2, 2] = 16\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.apply-Tuple{GBMatrix}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.apply","text":"apply(u::GBVector; kwargs...) -> GBVector\n\nApply a Unary Operator to the entries of a vector u, creating a new vector.\n\nArguments\n\nu: the sparse vector.\n[out]: the output vector for result.\n[unaryop]: the unary operator to use.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out and mask.\n\nExamples\n\njulia> u = from_vector([-1, 2, -3]);\n\njulia> apply(u, unaryop = Unaryop.ABS)\n3-element GBVector{Int64} with 3 stored entries:\n  [1] = 1\n  [2] = 2\n  [3] = 3\n\n\n\n\n\napply(A::GBMatrix; kwargs...)\n\nApply a Unary Operator to the entries of a matrix A, creating a new matrix.\n\nArguments\n\nA: the sparse matrix.\n[out]: the output matrix for result.\n[unaryop]: the Unary Operator to use.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask and A.\n\nExamples\n\njulia> A = from_matrix([-1 2; -3 -4]);\n\njulia> apply(A, unaryop = Unaryop.ABS)\n2x2 GBMatrix{Int64} with 4 stored entries:\n  [1, 1] = 1\n  [1, 2] = 2\n  [2, 1] = 3\n  [2, 2] = 4\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.apply!-Tuple{GBMatrix}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.apply!","text":"apply!(A::GBMatrix; kwargs...)\n\nApply a Unary Operator to the entries of a matrix A.\n\nArguments\n\nA: the sparse matrix.\n[unaryop]: the Unary Operator to use.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for maskandA`.\n\nExamples\n\njulia> A = from_matrix([-1 2; -3 -4]);\n\njulia> apply!(A, unaryop = Unaryop.ABS);\n\njulia> A\n2x2 GBMatrix{Int64} with 4 stored entries:\n  [1, 1] = 1\n  [1, 2] = 2\n  [2, 1] = 3\n  [2, 2] = 4\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.select-Tuple{GBMatrix,SelectOperator}","page":"Matrix operations","title":"SuiteSparseGraphBLAS.select","text":"select(A::GBMatrix, op::SelectOperator; kwargs...)\n\nApply a Select Operator to the entries of a matrix A.\n\nArguments\n\nA: the sparse matrix.\nop: the Select Operator to use.\n[out]: the output matrix for result.\n[thunk]: optional input for the Select Operator.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask and A.\n\nExamples\n\njulia> A = from_matrix([1 2; 3 4]);\n\n# TODO: insert example\n\n\n\n\n\n","category":"method"},{"location":"matrix/#SuiteSparseGraphBLAS.reduce_vector","page":"Matrix operations","title":"SuiteSparseGraphBLAS.reduce_vector","text":"reduce_vector(A::GBMatrix; kwargs...)\n\nReduce a matrix A to a column vector using an operator. Normally the operator is a Binary Operator, in which all the three domains must be the same. It can be used a Monoid as an operator. In both cases the reduction operator must be commutative and associative.\n\nArguments\n\nA: the sparse matrix.\n[out]: the output matrix for result.\n[operator]: reduce operator.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask and A.\n\nExamples\n\njulia> A = from_matrix([1 2; 3 4]);\n\njulia> reduce_vector(A, operator = Binaryop.PLUS)\n2-element GBVector{Int64} with 2 stored entries:\n  [1] = 3\n  [2] = 7\n\n\n\n\n\n","category":"function"},{"location":"matrix/#SuiteSparseGraphBLAS.reduce_scalar","page":"Matrix operations","title":"SuiteSparseGraphBLAS.reduce_scalar","text":"reduce_scalar(A::GBMatrix{T}; kwargs...) -> T\n\nReduce a matrix A to a scalar, using the given Monoid.\n\nArguments\n\nA: the sparse matrix to reduce.\n[monoid]: monoid to do the reduction.\n[accum]: optional accumulator.\n[desc]: descriptor for A.\n\nExamples\n\njulia> A = from_matrix([1 2; 3 4]);\n\njulia> reduce_scalar(A, monoid = Monoids.PLUS)\n10\n\n\n\n\n\n","category":"function"},{"location":"matrix/#Base.transpose","page":"Matrix operations","title":"Base.transpose","text":"transpose(A::GBMatrix; kwargs...)\n\nTranspose a matrix A.\n\nArguments\n\nA: the sparse matrix to transpose.\n[out]: the output matrix for result.\n[mask]: optional mask.\n[accum]: optional accumulator.\n[desc]: descriptor for out, mask and A.\n\nExamples\n\njulia> A = from_matrix([1 2 3; 4 5 6]);\n\njulia> transpose(A)\n3x2 GBMatrix{Int64} with 6 stored entries:\n  [1, 1] = 1\n  [1, 2] = 4\n  [2, 1] = 2\n  [2, 2] = 5\n  [3, 1] = 3\n  [3, 2] = 6\n\n\n\n\n\n","category":"function"},{"location":"matrix/#Base.kron","page":"Matrix operations","title":"Base.kron","text":"kron(A::GBMatrix, B::GBMatrix; kwargs...)\n\nCompute the Kronecker product, using the given Binary Operator.\n\nArguments\n\nA: the first matrix.\nB: the second matrix.\n[out]: the output matrix for result.\n[binaryop]: the Binary Operator to use.\n[mask]: optional mask.\n[accum]: optional accumulator.\n[desc]: descriptor for out, mask and A.\n\nExamples\n\njulia> A = from_matrix[1 2; 3 4]);\n\njulia> B = copy(A)\n\njulia> Matrix(kron(A, B, binaryop = Binaryop.TIMES))\n4×4 Array{Int64,2}:\n 1   2   2   4\n 3   4   6   8\n 3   6   4   8\n 9  12  12  16\n\n\n\n\n\n","category":"function"},{"location":"operator/#","page":"Operators","title":"Operators","text":"unaryop\nbinaryop\nmonoid\nsemiring","category":"page"},{"location":"operator/#SuiteSparseGraphBLAS.unaryop","page":"Operators","title":"SuiteSparseGraphBLAS.unaryop","text":"unaryop(fun; [xtype, ztype], [name])\n\nCreate a UnaryOperator from the given function fun. Function fun must take only one parameter. It is possible to give an hint of the future use of the UnaryOperator, providing the input and the output domains, through xtype and ztype, respectively. If a name is provided, the Unary Operator is inserted in the global variable Unaryop.\n\nExamples\n\njulia> unaryop = unaryop((a) -> 2a, name = :DOUBLE);\n\njulia> unaryop === Unaryop.DOUBLE\ntrue\n\n\n\n\n\n","category":"function"},{"location":"operator/#SuiteSparseGraphBLAS.binaryop","page":"Operators","title":"SuiteSparseGraphBLAS.binaryop","text":"binaryop(fun; [xtype, ytype, ztype], [name])\n\nCreate a BinaryOperator from the given function fun. Function fun must take two parameters. It is possible to give an hint of the future use of the BinaryOperator, providing the inputs and the output domains, through xtype, ytype and ztype, respectively. If a name is provided, the Binary Operator is inserted in the global variable Binaryop.\n\nExamples\n\njulia> binaryop = binaryop((a, b) -> a÷b, name = :DIV);\n\njulia> binaryop === Binaryop.DIV\ntrue\n\n\n\n\n\n","category":"function"},{"location":"operator/#SuiteSparseGraphBLAS.monoid","page":"Operators","title":"SuiteSparseGraphBLAS.monoid","text":"monoid(bin_op, identity; [name])\n\nCreate a Monoid from the associative Binary Operator bin_op and the identity value. If a name is provided, the Monoid is inserted in the global variable Monoids.\n\nExamples\n\njulia> binaryop = binaryop((a, b) -> a÷b);\n\njulia> monoid = monoid(binaryop, 1, name=:DIV_MONOID);\n\njulia> monoid === Monoids.DIV_MONOID\ntrue\n\n\n\n\n\n","category":"function"},{"location":"operator/#SuiteSparseGraphBLAS.semiring","page":"Operators","title":"SuiteSparseGraphBLAS.semiring","text":"semiring(add, mult; [name])\n\nCreate a Semiring from the commutative and associative Monoid add and the Binary Operator mult. If a name is provided, the Semiring is inserted in the global variable Semirings.\n\nExamples\n\njulia> semiring = semiring(Monoids.LAND, Binaryop.EQ, name=:USER_DEFINED);\n\njulia> semiring === Semirings.USER_DEFINED\ntrue\n\n\n\n\n\n","category":"function"},{"location":"vector/#","page":"Vector operations","title":"Vector operations","text":"from_type(::DataType, ::Int64)\nfrom_lists(::Vector, ::Vector)\nfrom_vector\nsize(::GBVector)\n==(::GBVector, ::GBVector)\ncopy(::GBVector)\nnnz(::GBVector)\nfindnz(::GBVector)\nclear!(::GBVector)\nVector(::GBVector)\nlastindex(::GBVector)\nemult(::GBVector, ::GBVector)\neadd(::GBVector, ::GBVector)\nvxm\napply(::GBVector)\napply!(::GBVector)\nreduce","category":"page"},{"location":"vector/#SuiteSparseGraphBLAS.from_type-Tuple{DataType,Int64}","page":"Vector operations","title":"SuiteSparseGraphBLAS.from_type","text":"from_type(type, n)\n\nCreate an empty GBVector of size n from the given type type.\n\n\n\n\n\n","category":"method"},{"location":"vector/#SuiteSparseGraphBLAS.from_lists-Tuple{Array{T,1} where T,Array{T,1} where T}","page":"Vector operations","title":"SuiteSparseGraphBLAS.from_lists","text":"from_lists(I, V; n = nothing, type = nothing, combine = Binaryop.FIRST)\n\nCreate a new GBVector from the given lists of indices and values. If n is not provided, it is computed from the max value of the indices list. If type is not provided, it is inferred from the values list. A combiner Binary Operator can be provided to manage duplicates values. If it is not provided, the default BinaryOp.FIRST is used.\n\nArguments\n\nI: the list of indices.\nV: the list of values.\n[n]: the size of the vector.\n[type]: the type of the elements of the vector.\ncombine: the BinaryOperator which assembles any duplicate entries with identical indices.\n\nExamples\n\njulia> from_lists([1,2,5], [1,4,2])\n5-element GBVector{Int64} with 3 stored entries:\n  [1] = 1\n  [2] = 4\n  [5] = 2\n\njulia> from_lists([1,2,5], [1,4,2], type=Float32)\n5-element GBVector{Float32} with 3 stored entries:\n  [1] = 1.0\n  [2] = 4.0\n  [5] = 2.0\n\njulia> from_lists([1,2,5], [1,4,2], n=10)\n10-element GBVector{Int64} with 3 stored entries:\n  [1] = 1\n  [2] = 4\n  [5] = 2\n\njulia> from_lists([1,2,1,2,5], [1,4,2,4,2], combine=Binaryop.PLUS)\n5-element GBVector{Int64} with 3 stored entries:\n  [1] = 3\n  [2] = 8\n  [5] = 2\n\n\n\n\n\n","category":"method"},{"location":"vector/#SuiteSparseGraphBLAS.from_vector","page":"Vector operations","title":"SuiteSparseGraphBLAS.from_vector","text":"from_vector(V)\n\nCreate a GBVector from the given Vector m.\n\njulia> from_vector([1, 0, 0, 1, 2, 0])\n6-element GBVector{Int64} with 3 stored entries:\n  [1] = 1\n  [4] = 1\n  [5] = 2\n\n\n\n\n\n","category":"function"},{"location":"vector/#Base.size-Tuple{GBVector}","page":"Vector operations","title":"Base.size","text":"size(v::GBVector)\n\nReturn the dimension of v. Optionally you can specify a dimension to just get the length of that dimension.\n\nExamples\n\njulia> v = from_vector([1, 2, 3]);\n\njulia> size(v)\n3\n\n\n\n\n\n","category":"method"},{"location":"vector/#Base.:==-Tuple{GBVector,GBVector}","page":"Vector operations","title":"Base.:==","text":"==(u, v) -> Bool\n\nCheck if two vectors u and v are equal.\n\n\n\n\n\n","category":"method"},{"location":"vector/#Base.copy-Tuple{GBVector}","page":"Vector operations","title":"Base.copy","text":"copy(v::GBVector)\n\nCreate a copy of v.\n\nExamples\n\njulia> v = from_vector([1, 0, 0, 1, 2, 0]);\n\njulia> u = copy(v)\n6-element GBVector{Int64} with 3 stored entries:\n  [1] = 1\n  [4] = 1\n  [5] = 2\n\njulia> u == v\ntrue\n\njulia> u === v\nfalse\n\n\n\n\n\ncopy(m::GBMatrix)\n\nCreate a copy of m.\n\nExamples\n\njulia> A = from_matrix([1 0 1; 0 0 2; 2 0 1]);\n\njulia> B = copy(A)\n3x3 GBMatrix{Int64} with 5 stored entries:\n  [1, 1] = 1\n  [1, 3] = 1\n  [2, 3] = 2\n  [3, 1] = 2\n  [3, 3] = 1\n\njulia> A == B\ntrue\n\njulia> A === B\nfalse\n\n\n\n\n\n","category":"method"},{"location":"vector/#SuiteSparseGraphBLAS.nnz-Tuple{GBVector}","page":"Vector operations","title":"SuiteSparseGraphBLAS.nnz","text":"nnz(v::GBVector)\n\nReturn the number of entries in a vector v.\n\nExamples\n\njulia> v = from_vector([1, 2, 0]);\n\njulia> nnz(v)\n2\n\n\n\n\n\n","category":"method"},{"location":"vector/#SuiteSparseGraphBLAS.findnz-Tuple{GBVector}","page":"Vector operations","title":"SuiteSparseGraphBLAS.findnz","text":"findnz(v::GBVector)\n\nReturn a tuple (I, V) where I is the indices lists of the \"non-zero\" values in m, and V is a list of \"non-zero\" values.\n\nExamples\n\njulia> v = from_vector([1, 2, 0, 0, 0, 1]);\n\njulia> findnz(v)\n([1, 2, 6], [1, 2, 1])\n\n\n\n\n\n","category":"method"},{"location":"vector/#SuiteSparseGraphBLAS.clear!-Tuple{GBVector}","page":"Vector operations","title":"SuiteSparseGraphBLAS.clear!","text":"clear!(v::GBVector)\n\nClear all entries from a vector v.\n\n\n\n\n\n","category":"method"},{"location":"vector/#Base.Vector-Tuple{GBVector}","page":"Vector operations","title":"Base.Vector","text":"Vector(A::GBVector{T}) -> Vector{T}\n\nConstruct a Vector{T} from a GBVector{T} A.\n\n\n\n\n\n","category":"method"},{"location":"vector/#Base.lastindex-Tuple{GBVector}","page":"Vector operations","title":"Base.lastindex","text":"lastindex(v::GBVector)\n\nReturn the last index of a vector v.\n\nExamples\n\njulia> v = from_vector([1, 2, 0, 0, 0, 1]);\n\njulia> lastindex(v)\n6\n\n\n\n\n\n","category":"method"},{"location":"vector/#SuiteSparseGraphBLAS.emult-Tuple{GBVector,GBVector}","page":"Vector operations","title":"SuiteSparseGraphBLAS.emult","text":"emult(u::GBVector, v::GBVector; kwargs...)\n\nCompute the element-wise \"multiplication\" of two vector u and v, using a Binary Operator, a Monoid or a Semiring. If given a Monoid, the additive operator of the monoid is used as the multiply binary operator. If given a Semiring, the multiply operator of the semiring is used as the multiply binary operator.\n\nArguments\n\nu: the first vector.\nv: the second vector.\n[out]: the output vector for result.\n[operator]: the operator to use. Can be either a Binary Operator, a Monoid or a Semiring.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask, u and v.\n\nExamples\n\njulia> u = from_vector([1, 2, 3, 4]);\n\njulia> v = copy(u);\n\njulia> emult(u, v, operator = Binaryop.PLUS)\n4-element GBVector{Int64} with 4 stored entries:\n  [1] = 2\n  [2] = 4\n  [3] = 6\n  [4] = 8\n\n\n\n\n\n","category":"method"},{"location":"vector/#SuiteSparseGraphBLAS.eadd-Tuple{GBVector,GBVector}","page":"Vector operations","title":"SuiteSparseGraphBLAS.eadd","text":"eadd(u::GBVector, v::GBVector; kwargs...)\n\nCompute the element-wise \"addition\" of two vectors u and v, using a Binary Operator, a Monoid or a Semiring. If given a Monoid, the additive operator of the monoid is used as the add binary operator. If given a Semiring, the additive operator of the semiring is used as the add binary operator.\n\nArguments\n\nu: the first vector.\nv: the second vector.\n[out]: the output vector for result.\n[operator]: the operator to use. Can be either a Binary Operator, a Monoid or a Semiring.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask, u and v.\n\nExamples\n\njulia> u = from_vector([1, 2, 3, 4]);\n\njulia> v = copy(u);\n\njulia> eadd(u, v, operator = Binaryop.TIMES)\n4-element GBVector{Int64} with 4 stored entries:\n  [1] = 1\n  [2] = 4\n  [3] = 9\n  [4] = 16\n\n\n\n\n\n","category":"method"},{"location":"vector/#SuiteSparseGraphBLAS.vxm","page":"Vector operations","title":"SuiteSparseGraphBLAS.vxm","text":"vxm(u::GBVector, A::GBMatrix; kwargs...) -> GBVector\n\nMultiply a row vector u times a matrix A.\n\nArguments\n\nu: the row vector.\nA: the sparse matrix.\n[out]: the output vector for result.\n[semiring]: the semiring to use.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask and A.\n\nExamples\n\njulia> u = from_vector([1, 2]);\n\njulia> A = from_matrix([1 2; 3 4]);\n\njulia> vxm(u, A, semiring = Semirings.PLUS_TIMES)\n2-element GBVector{Int64} with 2 stored entries:\n  [1] = 7\n  [2] = 10\n\n\n\n\n\n","category":"function"},{"location":"vector/#SuiteSparseGraphBLAS.apply-Tuple{GBVector}","page":"Vector operations","title":"SuiteSparseGraphBLAS.apply","text":"apply(u::GBVector; kwargs...) -> GBVector\n\nApply a Unary Operator to the entries of a vector u, creating a new vector.\n\nArguments\n\nu: the sparse vector.\n[out]: the output vector for result.\n[unaryop]: the unary operator to use.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out and mask.\n\nExamples\n\njulia> u = from_vector([-1, 2, -3]);\n\njulia> apply(u, unaryop = Unaryop.ABS)\n3-element GBVector{Int64} with 3 stored entries:\n  [1] = 1\n  [2] = 2\n  [3] = 3\n\n\n\n\n\napply(A::GBMatrix; kwargs...)\n\nApply a Unary Operator to the entries of a matrix A, creating a new matrix.\n\nArguments\n\nA: the sparse matrix.\n[out]: the output matrix for result.\n[unaryop]: the Unary Operator to use.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out, mask and A.\n\nExamples\n\njulia> A = from_matrix([-1 2; -3 -4]);\n\njulia> apply(A, unaryop = Unaryop.ABS)\n2x2 GBMatrix{Int64} with 4 stored entries:\n  [1, 1] = 1\n  [1, 2] = 2\n  [2, 1] = 3\n  [2, 2] = 4\n\n\n\n\n\n","category":"method"},{"location":"vector/#SuiteSparseGraphBLAS.apply!-Tuple{GBVector}","page":"Vector operations","title":"SuiteSparseGraphBLAS.apply!","text":"apply!(A::GBMatrix; kwargs...)\n\nApply a Unary Operator to the entries of a vector u.\n\nArguments\n\nu: the sparse vector.\n[unaryop]: the unary operator to use.\n[accum]: optional accumulator.\n[mask]: optional mask.\n[desc]: descriptor for out and mask.\n\nExamples\n\njulia> u = from_vector([-1, 2, -3]);\n\njulia> apply!(u, unaryop = Unaryop.ABS);\n\njulia> u\n3-element GBVector{Int64} with 3 stored entries:\n  [1] = 1\n  [2] = 2\n  [3] = 3\n\n\n\n\n\n","category":"method"},{"location":"vector/#Base.reduce","page":"Vector operations","title":"Base.reduce","text":"reduce(u::GBVector{T}; kwargs...) -> T\n\nReduce a vector u to a scalar, using the given Monoid.\n\nArguments\n\nu: the sparse vector to reduce.\n[monoid]: monoid to do the reduction.\n[accum]: optional accumulator.\n\nExamples\n\njulia> u = from_vector([1, 2, 3, 4]);\n\njulia> reduce(u, monoid = Monoids.PLUS)\n10\n\n\n\n\n\n","category":"function"},{"location":"#SuiteSparseGraphBLAS.jl-1","page":"Home","title":"SuiteSparseGraphBLAS.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"SuiteSparseGraphBLAS.jl is a Julia wrapper for the SuiteSparse:GraphBLAS C library.","category":"page"}]
}
