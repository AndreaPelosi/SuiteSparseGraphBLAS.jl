@testset "Vector" begin

    # from_type method
    for t in valid_types
        type = SG.j2gtype(t)
        vector_type = SG.vector_from_type(type, 10)
        @test vector_type.type == type
        @test SG.size(vector_type) == 10
        I, X = SG.findnz(vector_type)
        @test isempty(I) && isempty(X)
    end

    # from_lists method

    # automatic type inference and size from values from lists
    I, X = [0,1,3,4], Int64[1,2,3,4]
    v = SG.vector_from_lists(I, X)
    @test v.type == INT64
    @test size(v) == 5

    # automatic type inference, given size
    I, X = [0,1,3,4], Int64[1,2,3,4]
    v = SG.vector_from_lists(I, X, size=10)
    @test v.type == INT64
    @test size(v) == 10

    # passed type parameter
    I, X = [0,1,3,4], Int8[1,2,3,4]
    v = SG.vector_from_lists(I, X, size=10, type=INT32)
    @test v.type == INT32
    @test size(v) == 10

    # combine parameter - default (FIRST)
    I, X = [0,0,3,4], Int8[1,2,3,4]
    v = SG.vector_from_lists(I, X, size=10)
    @test v.type == INT8
    @test size(v) == 10
    @test v[0] == 1
    @test SG.nnz(v) == 3

    # combine parameter - given
    I, X = [0,0,3,4], Int8[1,2,3,4]
    v = SG.vector_from_lists(I, X, combine=Binaryop.PLUS)
    @test v.type == INT8
    @test size(v) == 5
    @test v[0] == 3
    @test SG.nnz(v) == 3

    # findnz
    I, X = [0,1,3,4], Int8[1,2,3,4]
    v = SG.vector_from_lists(I, X)
    @test SG.findnz(v) == (I, X)

    # clear
    I, X = [0,1,3,4], Int8[1,2,3,4]
    v = SG.vector_from_lists(I, X)
    @test SG.findnz(v) == (I, X)
    SG.clear!(v)
    I, X = SG.findnz(v)
    @test isempty(I) && isempty(X)

    # getindex
    I, X = [0,1,2,3], Int8[1,2,3,4]
    v = SG.vector_from_lists(I, X)
    @test v[0] == 1
    @test v[1] == 2
    @test v[2] == 3
    @test v[3] == 4
    @test v[end] == v[3]
    @test typeof(v[0]) == Int8

    # setindex!
    I, X = [0,1,2,3], Int8[1,2,3,4]
    v = SG.vector_from_lists(I, X)
    v[0] = 10
    v[1] = 20
    @test v[0] == 10
    @test v[1] == 20
    @test v[2] == 3
    @test v[3] == 4
    @test v[end] == v[3]

end
