valid_types = [Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64]
all_op(d) = filter(x->x != Symbol(split(string(d), ".")[end]), names(d, all = true))
count(d) = sum(map(x->length(getproperty(d, x).impl), all_op(d)))

@testset "Unary Operations" begin

    # built-in unary ops
    @test length(all_op(Unaryop)) == 6
    @test count(Unaryop) == 66


    SG.unaryop(a->a, name = :NO_TYPE)
    @test hasproperty(Unaryop, :NO_TYPE)
    uop_no_type = Unaryop.NO_TYPE
    @test isempty(uop_no_type.impl)

    # same unaryop
    for type in valid_types
        t = xtype = SG.j2gtype(type)
        SG.unaryop(a->a, xtype = t, ztype = t, name = :SAME_TYPE)
        uop_type = Unaryop.SAME_TYPE
        tmp = SG._get(uop_type, t, t)
        @test isa(tmp, SG.GrB_UnaryOp)
        @test tmp.xtype == t
        @test tmp.ztype == t
    end
    @test length(Unaryop.SAME_TYPE.impl) == length(valid_types)

    # different unary ops
    for type in valid_types
        t = xtype = SG.j2gtype(type)
        name = Symbol(:TYPE_, string(type))
        SG.unaryop(a->a, xtype = t, ztype = t, name = name)
        uop = getproperty(Unaryop, name)
        tmp = SG._get(uop, t, t)
        @test isa(tmp, SG.GrB_UnaryOp)
        @test tmp.xtype == t
        @test tmp.ztype == t
        @test length(uop.impl) == 1
    end
    
end

@testset "Binary Operations" begin

    # built-in binary ops
    @test length(all_op(Binaryop)) == 17 + 6
    @test count(Binaryop) == 253

    
    SG.binaryop((a, b)->a, name = :NO_TYPE)
    @test hasproperty(Binaryop, :NO_TYPE)
    bop_no_type = Binaryop.NO_TYPE
    @test isempty(bop_no_type.impl)

    # same binary op
    for type in valid_types
        t = SG.j2gtype(type)
        SG.binaryop((a, b)->a+b; xtype = t, ytype = t, ztype = t, name = :SAME_TYPE)
        bop_type = Binaryop.SAME_TYPE
        tmp = SG._get(bop_type, t, t, t)
        @test isa(tmp, SG.GrB_BinaryOp)
        @test tmp.xtype == t
        @test tmp.ytype == t
        @test tmp.ztype == t
    end

    # different binary ops
    for type in valid_types
        t = SG.j2gtype(type)
        name = Symbol(:TYPE_, string(type))
        SG.binaryop((a, b)->a+b, xtype = t, ytype = t, ztype = t, name = name)
        bop = getproperty(Binaryop, name)
        tmp = SG._get(bop, t, t, t)
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

    mon_plus = SG.monoid(bop, Int64(0), name = :MON_PLUS)
    @test length(mon_plus.impl) == 1
    @test hasproperty(Monoids, :MON_PLUS)
    @test mon_plus.impl[1].domain == INT64

    mon_plus_clone = SG.monoid(bop, Int8(0), name = :MON_PLUS)
    @test length(mon_plus_clone.impl) == 2
    @test mon_plus.impl[2].domain == INT8
    @test mon_plus_clone === mon_plus
    @test hasproperty(Monoids, :MON_PLUS)

    mon_plus_fp64 = SG.monoid(bop, Float64(0), name=:MON_PLUS)
    @test length(mon_plus_fp64.impl) == 3
    @test mon_plus_fp64.impl[3].domain == FP64
    @test mon_plus_fp64 === mon_plus
    @test hasproperty(Monoids, :MON_PLUS)

    mon2 = SG.monoid(bop, Int8(0), name=:DUPLICATE)
    @test length(mon2.impl) == 1
    mon_duplicate = SG.monoid(bop, Int8(0), name=:DUPLICATE)
    @test length(mon2.impl) == 1
    @test length(mon_duplicate.impl) == 1
    @test mon2 === mon_duplicate

    
    # get_monoid
    for t in valid_types
        type = SG.j2gtype(t)
        mon = SG.monoid(bop, t(0), name=:TEST_MONOID)
        @test SG._get(mon, type).domain == type
    end

end

@testset "Semirings" begin

    # built-in monoids
    @test count(Semirings) == 960

    # monoid and binary op built in
    mon = Monoids.PLUS
    bop = Binaryop.PLUS
    sem = SG.semiring(mon, bop, name=:SEM_BUILTIN)
    @test hasproperty(Semirings, :SEM_BUILTIN)
    @test isa(sem, SG.Semiring)
    @test sem.monoid == mon
    @test sem.binaryop == bop
    @test isempty(sem.impl)

    sem_int64 = SG._get(sem, INT64, INT64, INT64)
    @test isa(sem_int64, SG.GrB_Semiring)
    @test sem_int64.xtype == INT64 && sem_int64.ytype == INT64 && sem_int64.ztype == INT64
    @test length(Semirings.SEM_BUILTIN.impl) == 1

    # user defined
    bop = SG.binaryop((a, b)->a + b, name=:BOP_USER)
    mon = SG.monoid(bop, Int64(0), name=:MON_USER)
    mon = SG.monoid(bop, Int8(0), name=:MON_USER)
    sem1 = SG.semiring(mon, bop, name=:SEM_USER)
    @test isa(sem1, SG.Semiring)
    sem_int64 = SG._get(sem1, INT64, INT64, INT64)
    @test sem_int64.xtype == INT64
    @test sem_int64.ytype == INT64
    @test sem_int64.ztype == INT64
    sem_int8 = SG._get(sem1, INT8, INT64, INT64)
    @test sem_int8.xtype == INT64
    @test sem_int8.ytype == INT64
    @test sem_int8.ztype == INT8
    

end
