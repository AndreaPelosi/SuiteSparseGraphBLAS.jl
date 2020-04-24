@testset "Matrix" begin

    # from_type method
    for t in valid_types
        type = SG.j2gtype(t)
        matrix_type = SG.matrix_from_type(type, 1, 2)
        @test matrix_type.type == type
        @test SG.size(matrix_type) == (1, 2)
        I, J, X = SG.findnz(matrix_type)
        @test isempty(I) && isempty(J) && isempty(X)
    end

    # from_lists tests

    # automatic type inference and size from values list
    I, J, X = [0, 0], [0, 1], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (1, 2)
    
    # automatic type inference, nvals and ncols given
    I, J, X = [0, 0], [0, 1], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 3)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (2, 3)

    # passed type parameter
    I, J, X = [0, 0], [0, 1], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 3, type = INT32)
    @test matrix_filled.type == INT32
    @test size(matrix_filled) == (2, 3)

    # combine parameter - default (FIRST)
    I, J, X = [0, 0], [0, 0], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 3)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (2, 3)
    @test matrix_filled[0,0] == 2
    # @test SG.nnz(matrix_filled) == 1

    # combine parameter - given
    I, J, X = [0, 0], [0, 0], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 3, combine = Binaryop.PLUS)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (2, 3)
    @test matrix_filled[0,0] == 5
    # @test SG.nnz(matrix_filled) == 1

    # square
    for t in valid_types
        type = SG.j2gtype(t)
        matrix_square = SG.matrix_from_type(type, 10, 10)
        @test SG.square(matrix_square)
        
        matrix_not_square = SG.matrix_from_type(type, 10, 11)
        @test !SG.square(matrix_not_square)
    end

    # findnz
    I, J, X = [0, 0], [0, 1], [2, 3]
    matrix = SG.matrix_from_lists(I, J, X)
    @test SG.findnz(matrix) == (I, J, X)

    # clear
    I, J, X = [0, 0], [0, 1], [2, 3]
    matrix = SG.matrix_from_lists(I, J, X)
    @test SG.findnz(matrix) == (I, J, X)
    SG.clear!(matrix)
    I, J, X = SG.findnz(matrix)
    @test isempty(I) && isempty(J) && isempty(X)

    # getindex
    I, J, X = [0, 0], [0, 1], [2, 3]
    matrix = SG.matrix_from_lists(I, J, X, nrows=2, ncols=2)
    @test matrix[0,0] == 2
    @test matrix[0,1] == 3
    @test matrix[1,0] == 0
    @test matrix[1,1] == 0

    # setindex
    I, J, X = [0, 0], [0, 1], [2, 3]
    matrix = SG.matrix_from_lists(I, J, X, nrows=2, ncols=2)
    matrix[0,0] = 10
    matrix[1,1] = 20
    @test matrix[0,0] == 10
    @test matrix[0,1] == 3
    @test matrix[1,0] == 0
    @test matrix[1,1] == 20

    # mxm
    # default out
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    B = SG.copy(A)
    out = SG.mxm(A, B, semiring=Semirings.PLUS_TIMES)
    @test out[0,0] == 7
    @test out[0,1] == 10
    @test out[1,0] == 15
    @test out[1,1] == 22
    @test out.type == INT64

    # vxm
    v = SG.from_vector(Int64[1,2])
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], [1,2,3,4])
    out = SG.vxm(v, A, semiring=Semirings.PLUS_TIMES)
    @test size(out) == 2
    @test out[0] == 7
    @test out[1] == 10

    # mxv
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    v = SG.from_vector(Int64[1,2])
    out = SG.mxv(A, v, semiring=Semirings.PLUS_TIMES)
    @test size(out) == 2
    @test out[0] == 5
    @test out[1] == 11

    # emult

    # binary op
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    B = copy(A)
    out = SG.emult(A, B, operator=Binaryop.PLUS)
    @test size(out) == (2,2)
    @test out[0,0] == 2
    @test out[0,1] == 4
    @test out[1,0] == 6
    @test out[1,1] == 8

    # monoid
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    B = copy(A)
    out = SG.emult(A, B, operator=Monoids.PLUS)
    @test size(out) == (2,2)
    @test out[0,0] == 2
    @test out[0,1] == 4
    @test out[1,0] == 6
    @test out[1,1] == 8

    # semiring
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    B = copy(A)
    out = SG.emult(A, B, operator=Semirings.TIMES_PLUS)
    @test size(out) == (2,2)
    @test out[0,0] == 2
    @test out[0,1] == 4
    @test out[1,0] == 6
    @test out[1,1] == 8

    # eadd

    # binaryop
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    B = copy(A)
    out = SG.eadd(A, B, operator=Binaryop.TIMES)
    @test out[0,0] == 1
    @test out[0,1] == 4
    @test out[1,0] == 9
    @test out[1,1] == 16

    # monoid
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    B = copy(A)
    out = SG.eadd(A, B, operator=Monoids.TIMES)
    @test out[0,0] == 1
    @test out[0,1] == 4
    @test out[1,0] == 9
    @test out[1,1] == 16

    # apply
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[-1,2,-3,-4])
    out = SG.apply(A, unaryop = Unaryop.ABS)
    @test out.type == INT64
    @test size(out) == size(A)
    @test out[0,0] == 1
    @test out[0,1] == 2
    @test out[1,0] == 3
    @test out[1,1] == 4

    dup = SG.unaryop(:DUP_TEST, a->a*2)
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    out = SG.apply(A, unaryop = dup)
    @test out.type == INT64
    @test size(out) == size(A)
    @test out[0,0] == 2
    @test out[0,1] == 4
    @test out[1,0] == 6
    @test out[1,1] == 8

    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int8[1,2,3,4])
    out = SG.apply(A, unaryop = dup)
    @test out.type == INT8
    @test size(out) == size(A)
    @test out[0,0] == 2
    @test out[0,1] == 4
    @test out[1,0] == 6
    @test out[1,1] == 8

    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int8[1,2,3,4], type=FP64)
    out = SG.apply(A, unaryop = dup)
    @test out.type == FP64
    @test size(out) == size(A)
    @test out[0,0] == Float64(2)
    @test out[0,1] == Float64(4)
    @test out[1,0] == Float64(6)
    @test out[1,1] == Float64(8)


    # apply!

    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[-1,2,-3,-4])
    SG.apply!(A, unaryop = Unaryop.ABS)
    @test A.type == INT64
    @test size(A) == (2,2)
    @test A[0,0] == 1
    @test A[0,1] == 2
    @test A[1,0] == 3
    @test A[1,1] == 4

    dup = SG.unaryop(:DUP_TEST, a->a*2)
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    SG.apply!(A, unaryop = dup)
    @test A.type == INT64
    @test A[0,0] == 2
    @test A[0,1] == 4
    @test A[1,0] == 6
    @test A[1,1] == 8

    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int8[1,2,3,4])
    SG.apply!(A, unaryop = dup)
    @test A.type == INT8
    @test A[0,0] == 2
    @test A[0,1] == 4
    @test A[1,0] == 6
    @test A[1,1] == 8

    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int8[1,2,3,4], type=FP64)
    out = SG.apply!(A, unaryop = dup)
    @test A.type == FP64
    @test A === out
    @test A[0,0] == Float64(2)
    @test A[0,1] == Float64(4)
    @test A[1,0] == Float64(6)
    @test A[1,1] == Float64(8)

    # reduce vector

    # binary op - square matrix
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    out = SG.reduce_vector(A, operator=Binaryop.PLUS)
    @test isa(out, SG.GBVector)
    @test size(out) == 2
    @test out[0] == 3
    @test out[1] == 7

    # binary op - rect matrix
    A = SG.matrix_from_lists([0,0,1,1,2,2], [0,1,0,1,0,1], Int64[1,2,3,4,5,6])
    out = SG.reduce_vector(A, operator=Binaryop.TIMES)
    @test isa(out, SG.GBVector)
    @test size(out) == 3
    @test out[0] == 2
    @test out[1] == 12
    @test out[2] == 30

    # monoid - square matrix
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    out = SG.reduce_vector(A, operator=Monoids.PLUS)
    @test isa(out, SG.GBVector)
    @test size(out) == 2
    @test out[0] == 3
    @test out[1] == 7

    # monoid - rect matrix
    A = SG.matrix_from_lists([0,0,1,1,2,2], [0,1,0,1,0,1], Int64[1,2,3,4,5,6])
    out = SG.reduce_vector(A, operator=Monoids.TIMES)
    @test isa(out, SG.GBVector)
    @test size(out) == 3
    @test out[0] == 2
    @test out[1] == 12
    @test out[2] == 30


    # reduce scalar
    # square matrix - int64
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    out = SG.reduce_scalar(A, monoid=Monoids.PLUS)
    @test isa(out, Int64)
    @test out == 10

    # square matrix - int64
    A = SG.matrix_from_lists([0,0,1,1,2,2], [0,1,0,1,0,1], Int64[1,2,3,4,5,6])
    out = SG.reduce_scalar(A, monoid=Monoids.PLUS)
    @test isa(out, Int64)
    @test out == 21

    # square matrix - fp64
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Float64[1,2,3,4])
    out = SG.reduce_scalar(A, monoid=Monoids.PLUS)
    @test isa(out, Float64)
    @test out == Float64(10)

    # square matrix - fp64
    A = SG.matrix_from_lists([0,0,1,1,2,2], [0,1,0,1,0,1], Float64[1,2,3,4,5,6])
    out = SG.reduce_scalar(A, monoid=Monoids.PLUS)
    @test isa(out, Float64)
    @test out == Float64(21)


    # transpose
    # square matrix
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    out = SG.transpose(A)
    @test size(out) == size(A)
    @test out[0,0] == 1
    @test out[0,1] == 3
    @test out[1,0] == 2
    @test out[1,1] == 4

    # rect matrix
    A = SG.matrix_from_lists([0,0,1,1,2,2], [0,1,0,1,0,1], Int64[1,2,3,4,5,6])
    out = SG.transpose(A)
    @test size(out) == (2,3)
    @test out[0,0] == 1
    @test out[0,1] == 3
    @test out[0,2] == 5
    @test out[1,0] == 2
    @test out[1,1] == 4
    @test out[1,2] == 6


    # # transpose!
    # # square matrix
    # A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    # SG.transpose!(A)
    # @test size(A) == (2,2)
    # @test A[0,0] == 1
    # @test A[0,1] == 3
    # @test A[1,0] == 2
    # @test A[1,1] == 4

    # # rect matrix
    # A = SG.matrix_from_lists([0,0,1,1,2,2], [0,1,0,1,0,1], Int64[1,2,3,4,5,6])
    # SG.transpose!(A)
    # @test size(A) == (2,3)
    # @test A[0,0] == 1
    # @test A[0,1] == 3
    # @test A[0,2] == 5
    # @test A[1,0] == 2
    # @test A[1,1] == 4
    # @test A[1,2] == 6


    # kron
    # square matrix
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    B = SG.copy(A)
    out = SG.kron(A, B, binaryop=Binaryop.TIMES)
    @test size(out) == (4,4)
    @test out[0,0] == 1 && out[0,1] == 2 && out[0,2] == 2 && out[0,3] == 4
    @test out[1,0] == 3 && out[1,1] == 4 && out[1,2] == 6 && out[1,3] == 8
    @test out[2,0] == 3 && out[2,1] == 6 && out[2,2] == 4 && out[2,3] == 8
    @test out[3,0] == 9 && out[3,1] == 12 && out[3,2] == 12 && out[3,3] == 16


    # extract col
    # square matrix
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    c1 = SG._extract_col(A, 0, [0,1])
    @test isa(c1, SG.GBVector)
    @test size(c1) == 2
    @test c1[0] == 1 && c1[1] == 3

    c2 = SG._extract_col(A, 1, [0,1])
    @test isa(c2, SG.GBVector)
    @test size(c2) == 2
    @test c2[0] == 2 && c2[1] == 4

    c3 = SG._extract_col(A, 0, [1])
    @test isa(c3, SG.GBVector)
    @test size(c3) == 1
    @test c3[0] == 3

    c4 = SG._extract_col(A, 1, [0])
    @test isa(c4, SG.GBVector)
    @test size(c4) == 1
    @test c4[0] == 2

    # rect matrix
    A = SG.matrix_from_lists([0,0,1,1,2,2], [0,1,0,1,0,1], Int64[1,2,3,4,5,6])
    c1 = SG._extract_col(A, 0, [0,1,2])
    @test isa(c1, SG.GBVector)
    @test size(c1) == 3
    @test c1[0] == 1 && c1[1] == 3 && c1[2] == 5

    c2 = SG._extract_col(A, 1, [0,1,2])
    @test isa(c2, SG.GBVector)
    @test size(c2) == 3
    @test c2[0] == 2 && c2[1] == 4 && c2[2] == 6

    c3 = SG._extract_col(A, 0, [0,2])
    @test isa(c3, SG.GBVector)
    @test size(c3) == 2
    @test c3[0] == 1 && c3[1] == 5

    c4 = SG._extract_col(A, 1, [1,2])
    @test isa(c4, SG.GBVector)
    @test size(c4) == 2
    @test c4[0] == 4 && c4[1] == 6


    # extract matrix
    # 2 x 2 matrix
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    out = SG._extract_matrix(A, [0,1], [0,1])
    @test isa(out, SG.GBMatrix)
    @test size(out) == (2,2)
    @test out[0,0] == 1
    @test out[0,1] == 2
    @test out[1,0] == 3
    @test out[1,1] == 4

    # 3 x 3 matrix
    A = SG.matrix_from_lists([0,0,0,1,1,1,2,2,2], [0,1,2,0,1,2,0,1,2], Int64[1,2,3,4,5,6,7,8,9])
    out = SG._extract_matrix(A, [0,2], [0,1])
    @test isa(out, SG.GBMatrix)
    @test size(out) == (2,2)
    @test out[0,0] == 1 && out[0,1] == 2
    @test out[1,0] == 7 && out[1,1] == 8


    # assign row
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    u = SG.from_vector([10,11])
    SG._assign_row!(A, u, 1, [0,1])
    @test A[0,0] == 1 && A[0,1] == 2
    @test A[1,0] == 10 && A[1,1] == 11


    # assign col
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    u = SG.from_vector([10,11])
    SG._assign_col!(A, u, 1, [0,1])
    @test A[0,0] == 1 && A[0,1] == 10
    @test A[1,0] == 3 && A[1,1] == 11

    
    # get index - colon, unitrange, vector indices ...
    # range of rows
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], Int64[1,2,3,4])
    u = A[0:1, 1]
    @test isa(u, SG.GBVector)
    @test u.type == INT64
    @test size(u) == 2
    @test u[0] == 2
    @test u[1] == 4

    A = SG.matrix_from_lists([0,0,1,1,2,2], [0,1,0,1,0,1], Int64[1,2,3,4,5,6])
    u = A[1:2, 1]
    @test isa(u, SG.GBVector)
    @test u.type == INT64
    @test size(u) == 2
    @test u[0] == 4
    @test u[1] == 6

    # select all rows with colon operator
    A = SG.matrix_from_lists([0,0,1,1,2,2], [0,1,0,1,0,1], Int64[1,2,3,4,5,6])
    u = A[:, 0]
    @test isa(u, SG.GBVector)
    @test u.type == INT64
    @test size(u) == 3
    @test u[0] == 1 && u[1] == 3 && u[2] == 5

    # select submatrix with row and col range
    A = SG.matrix_from_lists([0,0,0,1,1,1,2,2,2], [0,1,2,0,1,2,0,1,2], Int64[1,2,3,4,5,6,7,8,9])
    u = A[1:2, 1:2]
    @test isa(u, SG.GBMatrix)
    @test size(u) == (2,2)
    @test u.type == INT64
    @test u[0,0] == 5 && u[0,1] == 6
    @test u[1,0] == 8 && u[1,1] == 9

    # select submatrix with row and col vector indices
    A = SG.matrix_from_lists([0,0,0,1,1,1,2,2,2], [0,1,2,0,1,2,0,1,2], Int64[1,2,3,4,5,6,7,8,9])
    u = A[[0,2], [0,2]]
    @test isa(u, SG.GBMatrix)
    @test size(u) == (2,2)
    @test u.type == INT64
    @test u[0,0] == 1 && u[0,1] == 3
    @test u[1,0] == 7 && u[1,1] == 9

end