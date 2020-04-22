valid_types = [Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64]
count(d) = sum([length(d[k].impl) for k in keys(d)])

@testset "Unary Operations" begin

    # built-in unary ops
    @test length(keys(Unaryop)) == 6
    @test count(Unaryop) == 66


    SG.unaryop(:NO_TYPE, a->a)
    @test haskey(Unaryop, :NO_TYPE)
    uop_no_type = Unaryop.NO_TYPE
    @test isempty(uop_no_type.impl)

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
    @test length(Unaryop.SAME_TYPE.impl) == length(valid_types)

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
        @test length(uop.impl) == 1
    end
    
end

@testset "Binary Operations" begin

    # built-in binary ops
    @test length(keys(Binaryop)) == 17 + 6
    @test count(Binaryop) == 253

    
    SG.binaryop(:NO_TYPE, (a, b)->a)
    @test haskey(Binaryop, :NO_TYPE)
    bop_no_type = Binaryop.NO_TYPE
    @test isempty(bop_no_type.impl)

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
        @test length(bop.impl) == 1
    end

end

@testset "Monoids" begin

    # built-in monoids
    @test count(Monoids) == 44

    # monoid creation

    bop = Binaryop.PLUS

    mon_plus = SG.monoid(:MON_PLUS, bop, Int64(0))
    @test length(mon_plus.impl) == 1
    @test haskey(Monoids, :MON_PLUS)
    @test mon_plus.impl[1].domain == INT64

    mon_plus_clone = SG.monoid(:MON_PLUS, bop, Int8(0))
    @test length(mon_plus_clone.impl) == 2
    @test mon_plus.impl[2].domain == INT8
    @test mon_plus_clone === mon_plus
    @test haskey(Monoids, :MON_PLUS)

    mon_plus_fp64 = SG.monoid(:MON_PLUS, bop, Float64(0))
    @test length(mon_plus_fp64.impl) == 3
    @test mon_plus_fp64.impl[3].domain == FP64
    @test mon_plus_fp64 === mon_plus
    @test haskey(Monoids, :MON_PLUS)

    mon2 = SG.monoid(:DUPLICATE, bop, Int8(0))
    @test length(mon2.impl) == 1
    mon_duplicate = SG.monoid(:DUPLICATE, bop, Int8(0))
    @test length(mon2.impl) == 1
    @test length(mon_duplicate.impl) == 1
    @test mon2 === mon_duplicate

    
    # get_monoid
    for t in valid_types
        type = SG.j2gtype(t)
        mon = SG.monoid(:TEST_MONOID, bop, t(0))
        @test SG.get_monoid(mon, type).domain == type
    end

end

@testset "Semirings" begin

    # built-in monoids
    @test count(Semirings) == 960

    # monoid and binary op built in
    mon = Monoids.PLUS
    bop = Binaryop.PLUS
    sem = SG.semiring(:SEM_BUILTIN, mon, bop)
    @test haskey(Semirings, :SEM_BUILTIN)
    @test isa(sem, SG.Semiring)
    @test sem.monoid == mon
    @test sem.binaryop == bop
    @test isempty(sem.impl)

    sem_int64 = SG.get_semiring(sem, INT64, INT64, INT64)
    @test isa(sem_int64, SG.GrB_Semiring)
    @test sem_int64.xtype == INT64 && sem_int64.ytype == INT64 && sem_int64.ztype == INT64
    @test length(Semirings.SEM_BUILTIN.impl) == 1

    # user defined
    bop = SG.binaryop(:BOP_USER, (a,b)->a+b)
    mon = SG.monoid(:MON_USER, bop, Int64(0))
    mon = SG.monoid(:MON_USER, bop, Int8(0))
    sem1 = SG.semiring(:SEM_USER, mon, bop)
    @test isa(sem1, SG.Semiring)
    sem_int64 = SG.get_semiring(sem1, INT64, INT64, INT64)
    @test sem_int64.xtype == INT64
    @test sem_int64.ytype == INT64
    @test sem_int64.ztype == INT64
    sem_int8 = SG.get_semiring(sem1, INT8, INT64, INT64)
    @test sem_int8.xtype == INT64
    @test sem_int8.ytype == INT64
    @test sem_int8.ztype == INT8
    

end
