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
    I, J, X = [1, 1], [1, 2], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (1, 2)
    
    # automatic type inference, nvals and ncols given
    I, J, X = [1, 1], [1, 2], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 3)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (2, 3)

    # passed type parameter
    I, J, X = [1, 1], [1, 2], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 3, type = INT32)
    @test matrix_filled.type == INT32
    @test size(matrix_filled) == (2, 3)

    # combine parameter - default (FIRST)
    I, J, X = [1, 1], [1, 1], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 3)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (2, 3)
    @test matrix_filled[1,1] == 2
    @test SG.nnz(matrix_filled) == 1

    # combine parameter - given
    I, J, X = [1, 1], [1, 1], Int8[2, 3]
    matrix_filled = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 3, combine = Binaryop.PLUS)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (2, 3)
    @test matrix_filled[1,1] == 5
    @test SG.nnz(matrix_filled) == 1

    # square
    for t in valid_types
        type = SG.j2gtype(t)
        matrix_square = SG.matrix_from_type(type, 10, 10)
        @test SG.square(matrix_square)
        
        matrix_not_square = SG.matrix_from_type(type, 10, 11)
        @test !SG.square(matrix_not_square)
    end

    # from_matrix
    # int64
    A = SG.from_matrix(Int64[1 2 3; 0 4 5])
    @test A.type == INT64
    @test size(A) == (2, 3)
    @test A[1,1] == 1 && A[1,2] == 2 && A[1,3] == 3
    @test A[2,1] == 0 && A[2,2] == 4 && A[2,3] == 5
    @test SG.nnz(A) == 5
    
    # bool
    A = SG.from_matrix([true false false; true false true])
    @test A.type == BOOL
    @test size(A) == (2, 3)
    @test A[1,1] == true && A[1,2] == false && A[1,3] == false
    @test A[2,1] == true && A[2,2] == false && A[2,3] == true
    @test SG.nnz(A) == 3

    # int8
    A = SG.from_matrix(Int8[1 2 3; 0 4 5])
    @test A.type == INT8
    @test size(A) == (2, 3)
    @test A[1,1] == 1 && A[1,2] == 2 && A[1,3] == 3
    @test A[2,1] == 0 && A[2,2] == 4 && A[2,3] == 5
    @test SG.nnz(A) == 5

    # int16
    A = SG.from_matrix(Int16[1 2 3; 0 4 5])
    @test A.type == INT16
    @test size(A) == (2, 3)
    @test A[1,1] == 1 && A[1,2] == 2 && A[1,3] == 3
    @test A[2,1] == 0 && A[2,2] == 4 && A[2,3] == 5
    @test SG.nnz(A) == 5

    # int32
    A = SG.from_matrix(Int32[1 2 3; 0 4 5])
    @test A.type == INT32
    @test size(A) == (2, 3)
    @test A[1,1] == 1 && A[1,2] == 2 && A[1,3] == 3
    @test A[2,1] == 0 && A[2,2] == 4 && A[2,3] == 5
    @test SG.nnz(A) == 5

    # float32
    A = SG.from_matrix(Float32[1.0 2.0 3.0; 0.0 4.0 5.0])
    @test A.type == FP32
    @test size(A) == (2, 3)
    @test A[1,1] == 1.0 && A[1,2] == 2.0 && A[1,3] == 3.0
    @test A[2,1] == 0.0 && A[2,2] == 4.0 && A[2,3] == 5.0
    @test SG.nnz(A) == 5

    # float64
    A = SG.from_matrix(Float64[1.0 2.0 3.0; 0.0 4.0 5.0])
    @test A.type == FP64
    @test size(A) == (2, 3)
    @test A[1,1] == 1.0 && A[1,2] == 2.0 && A[1,3] == 3.0
    @test A[2,1] == 0.0 && A[2,2] == 4.0 && A[2,3] == 5.0
    @test SG.nnz(A) == 5


    # identity
    for s in 1:4
        for t in valid_types
            type = SG.j2gtype(t)
            
            m = SG.identity(type, s)
            @test m.type == type
            @test size(m) == (s, s)

            for i in 1:s
                for j in 1:s
                    if i == j
                        @test isone(m[i,j])
                    else
                        @test iszero(m[i,j])
                    end
                end
            end
        end  
    end    
    

    # findnz
    I, J, X = [1, 1], [1, 2], [2, 3]
    matrix = SG.matrix_from_lists(I, J, X)
    @test SG.findnz(matrix) == (I, J, X)

    # clear
    I, J, X = [1, 1], [1, 2], [2, 3]
    matrix = SG.matrix_from_lists(I, J, X)
    @test SG.findnz(matrix) == (I, J, X)
    SG.clear!(matrix)
    I, J, X = SG.findnz(matrix)
    @test isempty(I) && isempty(J) && isempty(X)

    # getindex
    I, J, X = [1, 1], [1, 2], [2, 3]
    matrix = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 2)
    @test matrix[1,1] == 2
    @test matrix[1,2] == 3
    @test matrix[2,1] == 0
    @test matrix[2,2] == 0

    # setindex
    I, J, X = [1, 1], [1, 2], [2, 3]
    matrix = SG.matrix_from_lists(I, J, X, nrows = 2, ncols = 2)
    matrix[1,1] = 10
    matrix[2,2] = 20
    @test matrix[1,1] == 10
    @test matrix[1,2] == 3
    @test matrix[2,1] == 0
    @test matrix[2,2] == 20

    # mxm
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.copy(A)
    out = SG.mxm(A, B, semiring = Semirings.PLUS_TIMES)
    @test out[1,1] == 7
    @test out[1,2] == 10
    @test out[2,1] == 15
    @test out[2,2] == 22
    @test out.type == INT64

    # mxm - default semiring (PLUS_TIMES)
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.copy(A)
    out = SG.mxm(A, B)
    @test out[1,1] == 7
    @test out[1,2] == 10
    @test out[2,1] == 15
    @test out[2,2] == 22
    @test out.type == INT64


    # mxv
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    v = SG.from_vector(Int64[1,2])
    out = SG.mxv(A, v, semiring = Semirings.PLUS_TIMES)
    @test size(out) == 2
    @test out[1] == 5
    @test out[2] == 11

    # mxv - default semiring (PLUS_TIMES)
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    v = SG.from_vector(Int64[1,2])
    out = SG.mxv(A, v)
    @test size(out) == 2
    @test out[1] == 5
    @test out[2] == 11

    # emult

    # binary op
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = copy(A)
    out = SG.emult(A, B, operator = Binaryop.PLUS)
    @test size(out) == (2, 2)
    @test out[1,1] == 2
    @test out[1,2] == 4
    @test out[2,1] == 6
    @test out[2,2] == 8

    # emult - default operator=binaryop (PLUS)
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = copy(A)
    out = SG.emult(A, B)
    @test size(out) == (2, 2)
    @test out[1,1] == 2
    @test out[1,2] == 4
    @test out[2,1] == 6
    @test out[2,2] == 8

    # monoid
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = copy(A)
    out = SG.emult(A, B, operator = Monoids.PLUS)
    @test size(out) == (2, 2)
    @test out[1,1] == 2
    @test out[1,2] == 4
    @test out[2,1] == 6
    @test out[2,2] == 8

    # semiring
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = copy(A)
    out = SG.emult(A, B, operator = Semirings.TIMES_PLUS)
    @test size(out) == (2, 2)
    @test out[1,1] == 2
    @test out[1,2] == 4
    @test out[2,1] == 6
    @test out[2,2] == 8

    # eadd

    # binaryop
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = copy(A)
    out = SG.eadd(A, B, operator = Binaryop.TIMES)
    @test out[1,1] == 1
    @test out[1,2] == 4
    @test out[2,1] == 9
    @test out[2,2] == 16

    # eadd - default operator=binaryop (PLUS)
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = copy(A)
    out = SG.eadd(A, B)
    @test out[1,1] == 2
    @test out[1,2] == 4
    @test out[2,1] == 6
    @test out[2,2] == 8

    # monoid
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = copy(A)
    out = SG.eadd(A, B, operator = Monoids.TIMES)
    @test out[1,1] == 1
    @test out[1,2] == 4
    @test out[2,1] == 9
    @test out[2,2] == 16

    # apply
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[-1,2,-3,-4])
    out = SG.apply(A, unaryop = Unaryop.ABS)
    @test out.type == INT64
    @test size(out) == size(A)
    @test out[1,1] == 1
    @test out[1,2] == 2
    @test out[2,1] == 3
    @test out[2,2] == 4

    dup = SG.unaryop(a->a * 2, name=:DUP_TEST)
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    out = SG.apply(A, unaryop = dup)
    @test out.type == INT64
    @test size(out) == size(A)
    @test out[1,1] == 2
    @test out[1,2] == 4
    @test out[2,1] == 6
    @test out[2,2] == 8

    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int8[1,2,3,4])
    out = SG.apply(A, unaryop = dup)
    @test out.type == INT8
    @test size(out) == size(A)
    @test out[1,1] == 2
    @test out[1,2] == 4
    @test out[2,1] == 6
    @test out[2,2] == 8

    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int8[1,2,3,4], type = FP64)
    out = SG.apply(A, unaryop = dup)
    @test out.type == FP64
    @test size(out) == size(A)
    @test out[1,1] == Float64(2)
    @test out[1,2] == Float64(4)
    @test out[2,1] == Float64(6)
    @test out[2,2] == Float64(8)


    # apply!

    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[-1,2,-3,-4])
    SG.apply!(A, unaryop = Unaryop.ABS)
    @test A.type == INT64
    @test size(A) == (2, 2)
    @test A[1,1] == 1
    @test A[1,2] == 2
    @test A[2,1] == 3
    @test A[2,2] == 4

    # apply! - default unaryop (ABS)
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[-1,2,-3,-4])
    SG.apply!(A)
    @test A.type == INT64
    @test size(A) == (2, 2)
    @test A[1,1] == 1
    @test A[1,2] == 2
    @test A[2,1] == 3
    @test A[2,2] == 4

    dup = SG.unaryop(a->a * 2)
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    SG.apply!(A, unaryop = dup)
    @test A.type == INT64
    @test A[1,1] == 2
    @test A[1,2] == 4
    @test A[2,1] == 6
    @test A[2,2] == 8

    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int8[1,2,3,4])
    SG.apply!(A, unaryop = dup)
    @test A.type == INT8
    @test A[1,1] == 2
    @test A[1,2] == 4
    @test A[2,1] == 6
    @test A[2,2] == 8

    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int8[1,2,3,4], type = FP64)
    out = SG.apply!(A, unaryop = dup)
    @test A.type == FP64
    @test A === out
    @test A[1,1] == Float64(2)
    @test A[1,2] == Float64(4)
    @test A[2,1] == Float64(6)
    @test A[2,2] == Float64(8)

    # reduce vector

    # binary op - square matrix
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    out = SG.reduce_vector(A, operator = Binaryop.PLUS)
    @test isa(out, SG.GBVector)
    @test size(out) == 2
    @test out[1] == 3
    @test out[2] == 7

    # binary op - rect matrix
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    out = SG.reduce_vector(A, operator = Binaryop.TIMES)
    @test isa(out, SG.GBVector)
    @test size(out) == 3
    @test out[1] == 2
    @test out[2] == 12
    @test out[3] == 30

    # monoid - square matrix
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    out = SG.reduce_vector(A, operator = Monoids.PLUS)
    @test isa(out, SG.GBVector)
    @test size(out) == 2
    @test out[1] == 3
    @test out[2] == 7

    # reduce_vector (square matrix) - default operator=monoid (PLUS)
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    out = SG.reduce_vector(A)
    @test isa(out, SG.GBVector)
    @test size(out) == 2
    @test out[1] == 3
    @test out[2] == 7

    # monoid - rect matrix
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    out = SG.reduce_vector(A, operator = Monoids.TIMES)
    @test isa(out, SG.GBVector)
    @test size(out) == 3
    @test out[1] == 2
    @test out[2] == 12
    @test out[3] == 30

    # reduce_vector (rect matrix) - default monoid (PLUS)
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    out = SG.reduce_vector(A)
    @test isa(out, SG.GBVector)
    @test size(out) == 3
    @test out[1] == 3
    @test out[2] == 7
    @test out[3] == 11


    # reduce scalar
    # square matrix - int64
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    out = SG.reduce_scalar(A, monoid = Monoids.PLUS)
    @test isa(out, Int64)
    @test out == 10

    # reduce_scalar (square matrix) - default monoid (PLUS) - int64
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    out = SG.reduce_scalar(A)
    @test isa(out, Int64)
    @test out == 10

    # rect matrix - int64
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    out = SG.reduce_scalar(A, monoid = Monoids.PLUS)
    @test isa(out, Int64)
    @test out == 21

    # reduce_scalar (rect matrix) - default monoid (PLUS) - int64
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    out = SG.reduce_scalar(A)
    @test isa(out, Int64)
    @test out == 21

    # square matrix - fp64
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Float64[1,2,3,4])
    out = SG.reduce_scalar(A, monoid = Monoids.PLUS)
    @test isa(out, Float64)
    @test out == Float64(10)

    # reduce_scalar (square matrix) - default monoid (PLUS) - fp64
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Float64[1,2,3,4])
    out = SG.reduce_scalar(A)
    @test isa(out, Float64)
    @test out == Float64(10)

    # rect matrix - fp64
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Float64[1,2,3,4,5,6])
    out = SG.reduce_scalar(A, monoid = Monoids.PLUS)
    @test isa(out, Float64)
    @test out == Float64(21)

    # reduce_scalar (rect matrix) - default monoid (PLUS) - fp64
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Float64[1,2,3,4,5,6])
    out = SG.reduce_scalar(A)
    @test isa(out, Float64)
    @test out == Float64(21)


    # transpose
    # square matrix
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    out = SG.transpose(A)
    @test size(out) == size(A)
    @test out[1,1] == 1
    @test out[1,2] == 3
    @test out[2,1] == 2
    @test out[2,2] == 4

    # adjoint
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    tran = A'
    @test size(tran) == (2, 3)
    @test tran[1,1] == 1 && tran[1,2] == 3 && tran[1,3] == 5
    @test tran[2,1] == 2 && tran[2,2] == 4 && tran[2,3] == 6

    # rect matrix
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    out = SG.transpose(A)
    @test size(out) == (2, 3)
    @test out[1,1] == 1
    @test out[1,2] == 3
    @test out[1,3] == 5
    @test out[2,1] == 2
    @test out[2,2] == 4
    @test out[2,3] == 6


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
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.copy(A)
    out = SG.kron(A, B, binaryop = Binaryop.TIMES)
    @test size(out) == (4, 4)
    @test out[1,1] == 1 && out[1,2] == 2 && out[1,3] == 2 && out[1,4] == 4
    @test out[2,1] == 3 && out[2,2] == 4 && out[2,3] == 6 && out[2,4] == 8
    @test out[3,1] == 3 && out[3,2] == 6 && out[3,3] == 4 && out[3,4] == 8
    @test out[4,1] == 9 && out[4,2] == 12 && out[4,3] == 12 && out[4,4] == 16

    # kron (square matrix) - default binaryop (PLUS)
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.copy(A)
    out = SG.kron(A, B)
    @test size(out) == (4, 4)
    @test out[1,1] == 2 && out[1,2] == 3 && out[1,3] == 3 && out[1,4] == 4
    @test out[2,1] == 4 && out[2,2] == 5 && out[2,3] == 5 && out[2,4] == 6
    @test out[3,1] == 4 && out[3,2] == 5 && out[3,3] == 5 && out[3,4] == 6
    @test out[4,1] == 6 && out[4,2] == 7 && out[4,3] == 7 && out[4,4] == 8


    # extract col
    # square matrix
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    c1 = SG._extract_col(A, 0, [0,1])
    @test isa(c1, SG.GBVector)
    @test size(c1) == 2
    @test c1[1] == 1 && c1[2] == 3

    c2 = SG._extract_col(A, 1, [0,1])
    @test isa(c2, SG.GBVector)
    @test size(c2) == 2
    @test c2[1] == 2 && c2[2] == 4

    c3 = SG._extract_col(A, 0, [1])
    @test isa(c3, SG.GBVector)
    @test size(c3) == 1
    @test c3[1] == 3

    c4 = SG._extract_col(A, 1, [0])
    @test isa(c4, SG.GBVector)
    @test size(c4) == 1
    @test c4[1] == 2

    # rect matrix
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    c1 = SG._extract_col(A, 0, [0,1,2])
    @test isa(c1, SG.GBVector)
    @test size(c1) == 3
    @test c1[1] == 1 && c1[2] == 3 && c1[3] == 5

    c2 = SG._extract_col(A, 1, [0,1,2])
    @test isa(c2, SG.GBVector)
    @test size(c2) == 3
    @test c2[1] == 2 && c2[2] == 4 && c2[3] == 6

    c3 = SG._extract_col(A, 0, [0,2])
    @test isa(c3, SG.GBVector)
    @test size(c3) == 2
    @test c3[1] == 1 && c3[2] == 5

    c4 = SG._extract_col(A, 1, [1,2])
    @test isa(c4, SG.GBVector)
    @test size(c4) == 2
    @test c4[1] == 4 && c4[2] == 6


    # extract row
    # square matrix
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    c1 = SG._extract_row(A, 0, [0,1])
    @test isa(c1, SG.GBVector)
    @test size(c1) == 2
    @test c1[1] == 1 && c1[2] == 2

    c2 = SG._extract_row(A, 1, [0,1])
    @test isa(c2, SG.GBVector)
    @test size(c2) == 2
    @test c2[1] == 3 && c2[2] == 4

    c3 = SG._extract_row(A, 0, [1])
    @test isa(c3, SG.GBVector)
    @test size(c3) == 1
    @test c3[1] == 2

    c4 = SG._extract_row(A, 1, [0])
    @test isa(c4, SG.GBVector)
    @test size(c4) == 1
    @test c4[1] == 3

    # rect matrix
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    c1 = SG._extract_row(A, 0, [0,1])
    @test isa(c1, SG.GBVector)
    @test size(c1) == 2
    @test c1[1] == 1 && c1[2] == 2

    c2 = SG._extract_row(A, 1, [0,1])
    @test isa(c2, SG.GBVector)
    @test size(c2) == 2
    @test c2[1] == 3 && c2[2] == 4



    # extract matrix
    # 2 x 2 matrix
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    out = SG._extract_matrix(A, [0,1], [0,1])
    @test isa(out, SG.GBMatrix)
    @test size(out) == (2, 2)
    @test out[1,1] == 1
    @test out[1,2] == 2
    @test out[2,1] == 3
    @test out[2,2] == 4

    # 3 x 3 matrix
    A = SG.matrix_from_lists([1,1,1,2,2,2,3,3,3], [1,2,3,1,2,3,1,2,3], Int64[1,2,3,4,5,6,7,8,9])
    out = SG._extract_matrix(A, [0,2], [0,1])
    @test isa(out, SG.GBMatrix)
    @test size(out) == (2, 2)
    @test out[1,1] == 1 && out[1,2] == 2
    @test out[2,1] == 7 && out[2,2] == 8


    # assign row
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    u = SG.from_vector([10,11])
    SG._assign_row!(A, u, 1, [0,1])
    @test A[1,1] == 1 && A[1,2] == 2
    @test A[2,1] == 10 && A[2,2] == 11


    # assign col
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    u = SG.from_vector([10,11])
    SG._assign_col!(A, u, 1, [0,1])
    @test A[1,1] == 1 && A[1,2] == 10
    @test A[2,1] == 3 && A[2,2] == 11


    # assign matrix
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[5,6,7,8])
    SG._assign_matrix!(A, B, [0,1], [0,1])
    @test A[1,1] == 5 && A[1,2] == 6
    @test A[2,1] == 7 && A[2,2] == 8

    A = SG.matrix_from_lists([1,1,1,2,2,2,3,3,3], [1,2,3,1,2,3,1,2,3], Int64[1,2,3,4,5,6,7,8,9])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[10,11,12,13])
    SG._assign_matrix!(A, B, [0,2], [1,2])
    @test A[1,1] == 1 && A[1,2] == 10 && A[1,3] == 11
    @test A[2,1] == 4 && A[2,2] == 5 && A[2,3] == 6
    @test A[3,1] == 7 && A[3,2] == 12 && A[3,3] == 13


    
    # get index - colon, unitrange, vector indices ...
    # range of rows
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    u = A[1:2, 2]
    @test isa(u, SG.GBVector)
    @test u.type == INT64
    @test size(u) == 2
    @test u[1] == 2
    @test u[2] == 4

    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    u = A[2:3, 2]
    @test isa(u, SG.GBVector)
    @test u.type == INT64
    @test size(u) == 2
    @test u[1] == 4
    @test u[2] == 6

    # range of cols
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    u = A[1, 1:2]
    @test isa(u, SG.GBVector)
    @test u.type == INT64
    @test size(u) == 2
    @test u[1] == 1
    @test u[2] == 2

    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    u = A[2, 1:2]
    @test isa(u, SG.GBVector)
    @test u.type == INT64
    @test size(u) == 2
    @test u[1] == 3
    @test u[2] == 4

    # select all rows with colon operator
    A = SG.matrix_from_lists([1,1,2,2,3,3], [1,2,1,2,1,2], Int64[1,2,3,4,5,6])
    u = A[:, 1]
    @test isa(u, SG.GBVector)
    @test u.type == INT64
    @test size(u) == 3
    @test u[1] == 1 && u[2] == 3 && u[3] == 5

    # select submatrix with row and col range
    A = SG.matrix_from_lists([1,1,1,2,2,2,3,3,3], [1,2,3,1,2,3,1,2,3], Int64[1,2,3,4,5,6,7,8,9])
    u = A[2:3, 2:3]
    @test isa(u, SG.GBMatrix)
    @test size(u) == (2, 2)
    @test u.type == INT64
    @test u[1,1] == 5 && u[1,2] == 6
    @test u[2,1] == 8 && u[2,2] == 9

    # select submatrix with row and col vector indices
    A = SG.matrix_from_lists([1,1,1,2,2,2,3,3,3], [1,2,3,1,2,3,1,2,3], Int64[1,2,3,4,5,6,7,8,9])
    u = A[[1,3], [1,3]]
    @test isa(u, SG.GBMatrix)
    @test size(u) == (2, 2)
    @test u.type == INT64
    @test u[1,1] == 1 && u[1,2] == 3
    @test u[2,1] == 7 && u[2,2] == 9



    # setindex!
    # index
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    A[1,1] = 10
    @test A[1,1] == 10 && A[1,2] == 2 && A[2,1] == 3 && A[2,2] == 4
    A[1,2] = 11
    @test A[1,1] == 10 && A[1,2] == 11 && A[2,1] == 3 && A[2,2] == 4
    A[2,1] = 12
    @test A[1,1] == 10 && A[1,2] == 11 && A[2,1] == 12 && A[2,2] == 4
    A[2,2] = 13
    @test A[1,1] == 10 && A[1,2] == 11 && A[2,1] == 12 && A[2,2] == 13

    # row colon, col index
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.from_vector([10, 11])
    A[:,1] = B
    @test A[1,1] == 10 && A[1,2] == 2 && A[2,1] == 11 && A[2,2] == 4

    # row index, col colon
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.from_vector([10, 11])
    A[2,:] = B
    @test A[1,1] == 1 && A[1,2] == 2 && A[2,1] == 10 && A[2,2] == 11

    # row list, col index
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.from_vector([10, 11])
    A[[1,2],1] = B
    @test A[1,1] == 10 && A[1,2] == 2 && A[2,1] == 11 && A[2,2] == 4

    # row index, col list
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.from_vector([10, 11])
    A[2,[1,2]] = B
    @test A[1,1] == 1 && A[1,2] == 2 && A[2,1] == 10 && A[2,2] == 11

    # row range, col index
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.from_vector([10, 11])
    A[1:2,1] = B
    @test A[1,1] == 10 && A[1,2] == 2 && A[2,1] == 11 && A[2,2] == 4

    # row index, col range
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.from_vector([10, 11])
    A[2,1:2] = B
    @test A[1,1] == 1 && A[1,2] == 2 && A[2,1] == 10 && A[2,2] == 11

    # row list, col list
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[10,20,30,40])
    A[[1,2],[1,2]] = B
    @test A[1,1] == 10 && A[1,2] == 20 && A[2,1] == 30 && A[2,2] == 40

    # row list, col list
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[10,20,30,40])
    A[[1,2],[1,2]] = B
    @test A[1,1] == 10 && A[1,2] == 20 && A[2,1] == 30 && A[2,2] == 40

    # row range, col range
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[10,20,30,40])
    A[1:2,1:2] = B
    @test A[1,1] == 10 && A[1,2] == 20 && A[2,1] == 30 && A[2,2] == 40

    # row range, col colon
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[10,20,30,40])
    A[1:2,:] = B
    @test A[1,1] == 10 && A[1,2] == 20 && A[2,1] == 30 && A[2,2] == 40

    # row colon, col range
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[10,20,30,40])
    A[:,1:2] = B
    @test A[1,1] == 10 && A[1,2] == 20 && A[2,1] == 30 && A[2,2] == 40

    # row list, col colon
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[10,20,30,40])
    A[[1,2],:] = B
    @test A[1,1] == 10 && A[1,2] == 20 && A[2,1] == 30 && A[2,2] == 40

    # row colon, col list
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[10,20,30,40])
    A[:,[1,2]] = B
    @test A[1,1] == 10 && A[1,2] == 20 && A[2,1] == 30 && A[2,2] == 40

    # row colon, col colon
    A = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[1,2,3,4])
    B = SG.matrix_from_lists([1,1,2,2], [1,2,1,2], Int64[10,20,30,40])
    A[:,:] = B
    @test A[1,1] == 10 && A[1,2] == 20 && A[2,1] == 30 && A[2,2] == 40

end