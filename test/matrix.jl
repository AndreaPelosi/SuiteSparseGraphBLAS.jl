@testset "Matrix" begin

    # from_type method
    for t in valid_types
        type = SG.j2gtype(t)
        matrix_type = SG.from_type(type, 1, 2)
        @test matrix_type.type == type
        @test SG.size(matrix_type) == (1, 2)
        I, J, X = SG.findnz(matrix_type)
        @test isempty(I) && isempty(J) && isempty(X)
    end

    # from_lists tests

    # automatic type inference and size from values list
    I, J, X = [0, 0], [0, 1], Int8[2, 3]
    matrix_filled = SG.from_lists(I, J, X)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (1, 2)
    
    # automatic type inference, nvals and ncols given
    I, J, X = [0, 0], [0, 1], Int8[2, 3]
    matrix_filled = SG.from_lists(I, J, X, nrows = 2, ncols = 3)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (2, 3)

    # passed type parameter
    I, J, X = [0, 0], [0, 1], Int8[2, 3]
    matrix_filled = SG.from_lists(I, J, X, nrows = 2, ncols = 3, type = INT32)
    @test matrix_filled.type == INT32
    @test size(matrix_filled) == (2, 3)

    # combine parameter - default (FIRST)
    I, J, X = [0, 0], [0, 0], Int8[2, 3]
    matrix_filled = SG.from_lists(I, J, X, nrows = 2, ncols = 3)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (2, 3)
    @test matrix_filled[0,0] == 2
    # @test SG.nnz(matrix_filled) == 1

    # combine parameter - given
    I, J, X = [0, 0], [0, 0], Int8[2, 3]
    matrix_filled = SG.from_lists(I, J, X, nrows = 2, ncols = 3, combine = Binaryop.PLUS)
    @test matrix_filled.type == INT8
    @test size(matrix_filled) == (2, 3)
    @test matrix_filled[0,0] == 5
    # @test SG.nnz(matrix_filled) == 1

    # square
    for t in valid_types
        type = SG.j2gtype(t)
        matrix_square = SG.from_type(type, 10, 10)
        @test SG.square(matrix_square)
        
        matrix_not_square = SG.from_type(type, 10, 11)
        @test !SG.square(matrix_not_square)
    end

    # findnz
    I, J, X = [0, 0], [0, 1], [2, 3]
    matrix = SG.from_lists(I, J, X)
    @test SG.findnz(matrix) == (I, J, X)

    # clear
    I, J, X = [0, 0], [0, 1], [2, 3]
    matrix = SG.from_lists(I, J, X)
    @test SG.findnz(matrix) == (I, J, X)
    SG.clear!(matrix)
    I, J, X = SG.findnz(matrix)
    @test isempty(I) && isempty(J) && isempty(X)

    # getindex
    I, J, X = [0, 0], [0, 1], [2, 3]
    matrix = SG.from_lists(I, J, X, nrows=2, ncols=2)
    @test matrix[0,0] == 2
    @test matrix[0,1] == 3
    @test matrix[1,0] == 0
    @test matrix[1,1] == 0

    # setindex
    I, J, X = [0, 0], [0, 1], [2, 3]
    matrix = SG.from_lists(I, J, X, nrows=2, ncols=2)
    matrix[0,0] = 10
    matrix[1,1] = 20
    @test matrix[0,0] == 10
    @test matrix[0,1] == 3
    @test matrix[1,0] == 0
    @test matrix[1,1] == 20


end