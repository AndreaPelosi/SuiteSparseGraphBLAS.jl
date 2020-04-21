valid_types = [Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64]

@testset "Unary Operations" begin

    # built-in unary ops
    count(d) = sum([length(d[k].gb_uops) for k in keys(d)])

    @test length(keys(Unaryop)) == 6
    @test count(Unaryop) == 66


    SG.unaryop(:NO_TYPE, a->a)
    @test haskey(Unaryop, :NO_TYPE)
    uop_no_type = Unaryop.NO_TYPE
    @test isempty(uop_no_type.gb_uops)

    # same unaryop
    for type in valid_types
        t = xtype = SG.j2gtype(type)
        SG.unaryop(:SAME_TYPE, a->a, xtype = t, ztype = t)
        uop_type = Unaryop.SAME_TYPE
        tmp = SG.get_unaryop(uop_type, t, t)
        @test isa(tmp, SG.GrB_UnaryOp)
        @test tmp.xtype == t
        @test tmp.ztype == t
    end
    @test length(Unaryop.SAME_TYPE.gb_uops) == length(valid_types)

    # different unary ops
    for type in valid_types
        t = xtype = SG.j2gtype(type)
        name = Symbol(:TYPE_, string(type))
        SG.unaryop(name, a->a, xtype = t, ztype = t)
        uop = Unaryop[name]
        tmp = SG.get_unaryop(uop, t, t)
        @test isa(tmp, SG.GrB_UnaryOp)
        @test tmp.xtype == t
        @test tmp.ztype == t
        @test length(uop.gb_uops) == 1
    end

    
    
end

@testset "Binary Operations" begin

    # built-in binary ops
    count(d) = sum([length(d[k].gb_bops) for k in keys(d)])

    @test length(keys(Binaryop)) == 17 + 6
    @test count(Binaryop) == 253

    
    SG.binaryop(:NO_TYPE, (a, b)->a)
    @test haskey(Binaryop, :NO_TYPE)
    bop_no_type = Binaryop.NO_TYPE
    @test isempty(bop_no_type.gb_bops)

    # same binary op
    for type in valid_types
        t = xtype = SG.j2gtype(type)
        SG.binaryop(:SAME_TYPE, (a, b)->a + b, xtype = t, ytype = t, ztype = t)
        bop_type = Binaryop.SAME_TYPE
        tmp = SG.get_binaryop(bop_type, t, t, t)
        @test isa(tmp, SG.GrB_BinaryOp)
        @test tmp.xtype == t
        @test tmp.ytype == t
        @test tmp.ztype == t
    end

    # different binary ops
    for type in valid_types
        t = xtype = SG.j2gtype(type)
        name = Symbol(:TYPE_, string(type))
        SG.binaryop(name, (a, b)->a + b, xtype = t, ytype = t, ztype = t)
        bop = Binaryop[name]
        tmp = SG.get_binaryop(bop, t, t, t)
        @test isa(tmp, SG.GrB_BinaryOp)
        @test tmp.xtype == t
        @test tmp.ytype == t
        @test tmp.ztype == t
        @test length(bop.gb_bops) == 1
    end

end

@testset "Monoids" begin

    # built-in monoids
    @test length(keys(Monoids)) == 48

    
    bop = Binaryop.PLUS

    monoid_plus_int8 = SG.monoid(:TEST_PLUS_INT8, bop, zero(Int8))
    @test haskey(Monoids, :TEST_PLUS_INT8)
    @test monoid_plus_int8.domain == INT8

    monoid_plus_int32 = SG.monoid(:TEST_PLUS_INT32, bop, zero(Int32))
    @test haskey(Monoids, :TEST_PLUS_INT32)
    @test monoid_plus_int32.domain == INT32

    

end

@testset "Semirings" begin

    # built-in monoids
    @test length(keys(Semirings)) == 960

end
