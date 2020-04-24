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

    # from_vector
    v = SG.from_vector(Int32[1,2,3])
    @test v.type == INT32
    @test v[0] == 1 && v[1] == 2 && v[2] == 3

    
    # emult

    # binary op
    u = SG.from_vector(Int64[1,2,3,4,5])
    v = SG.from_vector(Int64[6,7,8,9,10])
    out = SG.emult(u, v, operator=Binaryop.PLUS)
    @test size(out) == 5
    @test out.type == INT64
    @test out[0] == 7
    @test out[1] == 9
    @test out[2] == 11
    @test out[3] == 13
    @test out[4] == 15

    # monoid
    u = SG.from_vector(Int64[1,2,3,4,5])
    v = SG.from_vector(Int64[6,7,8,9,10])
    out = SG.emult(u, v, operator=Monoids.PLUS)
    @test size(out) == 5
    @test out.type == INT64
    @test out[0] == 7
    @test out[1] == 9
    @test out[2] == 11
    @test out[3] == 13
    @test out[4] == 15

    # semiring
    u = SG.from_vector(Int64[1,2,3,4,5])
    v = SG.from_vector(Int64[6,7,8,9,10])
    out = SG.emult(u, v, operator=Semirings.TIMES_PLUS)
    @test size(out) == 5
    @test out.type == INT64
    @test out[0] == 7
    @test out[1] == 9
    @test out[2] == 11
    @test out[3] == 13
    @test out[4] == 15


    # eadd

    # binary op
    u = SG.from_vector(Int64[1,2,3,4,5])
    v = SG.from_vector(Int64[6,7,8,9,10])
    out = SG.eadd(u, v, operator=Binaryop.TIMES)
    @test size(out) == 5
    @test out.type == INT64
    @test out[0] == 6
    @test out[1] == 14
    @test out[2] == 24
    @test out[3] == 36
    @test out[4] == 50

    # monoid
    u = SG.from_vector(Int64[1,2,3,4,5])
    v = SG.from_vector(Int64[6,7,8,9,10])
    out = SG.eadd(u, v, operator=Monoids.TIMES)
    @test size(out) == 5
    @test out.type == INT64
    @test out[0] == 6
    @test out[1] == 14
    @test out[2] == 24
    @test out[3] == 36
    @test out[4] == 50

    # semiring
    u = SG.from_vector(Int64[1,2,3,4,5])
    v = SG.from_vector(Int64[6,7,8,9,10])
    out = SG.eadd(u, v, operator=Semirings.TIMES_PLUS)
    @test size(out) == 5
    @test out.type == INT64
    @test out[0] == 6
    @test out[1] == 14
    @test out[2] == 24
    @test out[3] == 36
    @test out[4] == 50


    # vxm
    v = SG.from_vector(Int64[1,2])
    A = SG.matrix_from_lists([0,0,1,1], [0,1,0,1], [1,2,3,4])
    out = SG.vxm(v, A, semiring=Semirings.PLUS_TIMES)
    @test size(out) == 2
    @test out[0] == 7
    @test out[1] == 10


    # apply

    v = SG.from_vector(Int64[-1,-2,3,-4])
    out = SG.apply(v, unaryop=Unaryop.ABS)
    @test out.type == INT64
    @test size(v) == size(out)
    @test out[0] == 1
    @test out[1] == 2
    @test out[2] == 3
    @test out[3] == 4

    dup = SG.unaryop(:DUP_TEST, a->a*2)
    v = SG.from_vector(Int64[1,2,3,4])
    out = SG.apply(v, unaryop=dup)
    @test out.type == INT64
    @test size(v) == size(out)
    @test out[0] == 2
    @test out[1] == 4
    @test out[2] == 6
    @test out[3] == 8

    v = SG.from_vector(Int8[1,2,3,4])
    out = SG.apply(v, unaryop=dup)
    @test out.type == INT8
    @test size(v) == size(out)
    @test out[0] == 2
    @test out[1] == 4
    @test out[2] == 6
    @test out[3] == 8

    v = SG.from_vector(Float64[1,2,3,4])
    out = SG.apply(v, unaryop=dup)
    @test out.type == FP64
    @test size(v) == size(out)
    @test out[0] == Float64(2)
    @test out[1] == Float64(4)
    @test out[2] == Float64(6)
    @test out[3] == Float64(8)



    # apply!
    
    v = SG.from_vector(Int64[-1,-2,3,-4])
    SG.apply!(v, unaryop=Unaryop.ABS)
    @test v[0] == 1
    @test v[1] == 2
    @test v[2] == 3
    @test v[3] == 4

    v = SG.from_vector(Int64[1,2,3,4])
    SG.apply!(v, unaryop=dup)
    @test v[0] == 2
    @test v[1] == 4
    @test v[2] == 6
    @test v[3] == 8

    v = SG.from_vector(Int8[1,2,3,4])
    SG.apply!(v, unaryop=dup)
    @test v[0] == 2
    @test v[1] == 4
    @test v[2] == 6
    @test v[3] == 8

    v = SG.from_vector(Float64[1,2,3,4])
    SG.apply!(v, unaryop=dup)
    @test v[0] == Float64(2)
    @test v[1] == Float64(4)
    @test v[2] == Float64(6)
    @test v[3] == Float64(8)


    # reduce
    u = SG.from_vector(Int64[1,2,3,4,5])
    out = SG.reduce(u, monoid=Monoids.PLUS)
    @test typeof(out) == Int64
    @test out == 15

    u = SG.from_vector(Int64[1,2,10,4,5])
    out = SG.reduce(u, monoid=Monoids.MAX)
    @test out == 10

    u = SG.from_vector([true, false, true])
    out = SG.reduce(u, monoid=Monoids.LAND)
    @test out == false
    out = SG.reduce(u, monoid=Monoids.LOR)
    @test out == true


    # extract sub vector
    u = SG.from_vector(Int64[1,2,3,4,5])
    out = SG._extract(u, [0,4])
    @test size(out) == 2
    @test isa(out, SG.GBVector)
    @test out[0] == 1
    @test out[1] == 5


    # getindex
    u = SG.from_vector(Int64[1,2,3,4,5])
    out = u[[0,4]]
    @test size(out) == 2
    @test isa(out, SG.GBVector)
    @test out[0] == 1
    @test out[1] == 5

    u = SG.from_vector(Int64[1,2,3,4,5])
    out = u[2:4]
    @test size(out) == 3
    @test isa(out, SG.GBVector)
    @test out[0] == 3
    @test out[1] == 4
    @test out[2] == 5


    # assign!
    u = SG.from_vector(Int64[1,2,3,4,5])
    v = SG.from_vector([10,11])
    SG._assign!(u, v, [2,3])
    @test u[0] == 1
    @test u[1] == 2
    @test u[2] == 10
    @test u[3] == 11
    @test u[4] == 5



end
