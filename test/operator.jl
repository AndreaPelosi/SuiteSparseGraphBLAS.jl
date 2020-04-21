valid_types = [Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64]

@testset "Unary Operations" begin

    SG.unaryop(:NO_TYPE, a->a)
    @test haskey(Unaryop, :NO_TYPE)
    uop_no_type = Unaryop.NO_TYPE
    @test isempty(uop_no_type.gb_uops)

    # same unaryop
    for type in valid_types
        t = xtype=SG.j2gtype(type)
        SG.unaryop(:SAME_TYPE, a->a, xtype=t, ztype=t)
        uop_type = Unaryop.SAME_TYPE
        tmp = SG.get_unaryop(uop_type, t, t)
        @test isa(tmp, SG.GrB_UnaryOp)
        @test tmp.xtype == t
        @test tmp.ztype == t
    end
    @test length(Unaryop.SAME_TYPE.gb_uops) == length(valid_types)

    # different unary ops
    for type in valid_types
        t = xtype=SG.j2gtype(type)
        name = Symbol(:TYPE_, string(type))
        SG.unaryop(name, a->a, xtype=t, ztype=t)
        uop = Unaryop[name]
        tmp = SG.get_unaryop(uop, t, t)
        @test isa(tmp, SG.GrB_UnaryOp)
        @test tmp.xtype == t
        @test tmp.ztype == t
        @test length(uop.gb_uops) == 1
    end

    # built-in unary ops
    # TODO
    
end

@testset "Binary Operations" begin
    
    SG.binaryop(:NO_TYPE, (a,b)->a)
    @test haskey(Binaryop, :NO_TYPE)
    bop_no_type = Binaryop.NO_TYPE
    @test isempty(bop_no_type.gb_bops)

    # same binary op
    for type in valid_types
        t = xtype=SG.j2gtype(type)
        SG.binaryop(:SAME_TYPE, (a,b)->a+b, xtype=t, ytype=t, ztype=t)
        bop_type = Binaryop.SAME_TYPE
        tmp = SG.get_binaryop(bop_type, t, t, t)
        @test isa(tmp, SG.GrB_BinaryOp)
        @test tmp.xtype == t
        @test tmp.ytype == t
        @test tmp.ztype == t
    end

    # different binary ops
    for type in valid_types
        t = xtype=SG.j2gtype(type)
        name = Symbol(:TYPE_, string(type))
        SG.binaryop(name, (a,b)->a+b, xtype=t, ytype=t, ztype=t)
        bop = Binaryop[name]
        tmp = SG.get_binaryop(bop, t, t, t)
        @test isa(tmp, SG.GrB_BinaryOp)
        @test tmp.xtype == t
        @test tmp.ytype == t
        @test tmp.ztype == t
        @test length(bop.gb_bops) == 1
    end

    # built-in binary ops
    # TODO

end

@testset "Monoids" begin
    
    bop = Binaryop.PLUS

    SG.monoid(:PLUS_TEST, bop, Int32(0))
    @test haskey(Monoids, :PLUS_TEST)
    monoid = Monoids.PLUS_TEST
    @test length(monoid.ops) == 1
    SG.monoid(:PLUS_TEST, bop, Int8(0))
    @test length(monoid.ops) == 2
    @test findfirst(mon -> mon.domain == INT32, monoid.ops) != nothing
    @test findfirst(mon -> mon.domain == INT8, monoid.ops) != nothing

    mon_int32 = SG.get_monoid(monoid, INT32)
    @test isa(mon_int32, SG.GrB_Monoid)
    @test mon_int32.domain == INT32
    
    mon_int8 = SG.get_monoid(monoid, INT8)
    @test isa(mon_int8, SG.GrB_Monoid)
    @test mon_int8.domain == INT8

end

@testset "Semirings" begin

    

end
