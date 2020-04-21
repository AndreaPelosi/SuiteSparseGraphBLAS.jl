function semiring(s::Symbol, sum::Monoid, mult::BinaryOperator, xtype::GType, ytype=GType)
    bop = get_binaryop(mult, sum.domain, xtype, ytype)
    return semiring(s, sum, bop)
end

function semiring(s::Symbol, sum::Monoid, mult::GrB_BinaryOp)
    @assert sum.domain == mult.ztype
    if haskey(Semirings, s)
        error("semiring already exists")
    end
    semiring = GrB_Semiring_new(sum, mult)
    push!(Semirings, s => semiring)
    return semiring
end

function load_builtin_semiring()

    function load(lst; ztype = NULL)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype(string(bpn[end]))
            
            semiring_name = Symbol(join(bpn[2:end], "_"))
            semiring = Semiring(op, type, type, ztype == NULL ? type : ztype)
            push!(Semirings, semiring_name => semiring)
        end
    end

    gxb_alltype = compile(["GxB"],
    ["MIN", "MAX", "PLUS", "TIMES"],
    ["FIRST", "SECOND", "MIN", "MAX", "PLUS", "MINUS", "TIMES", "DIV", "ISEQ", "ISNE", "ISGT", "ISLT", "ISGE", "ISLE", "LOR", "LAND", "LXOR"],
    ["UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    gxb_comp = compile(["GxB"],
    ["LOR", "LAND", "LXOR", "EQ"],
    ["EQ", "NE", "GT", "LT", "GE", "LE"],
    ["UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    gxb_bool = compile(["GxB"],
    ["LOR", "LAND", "LXOR", "EQ"],
    ["FIRST", "SECOND", "LOR", "LAND", "LXOR", "EQ", "GT", "LT", "GE", "LE"],
    ["BOOL"])

    load(gxb_alltype)
    load(gxb_comp, ztype = BOOL)
    load(gxb_bool)
        
end

"""
    GrB_Semiring_new(monoid, binary_op)
Initialize a GraphBLAS semiring with specified monoid and binary operator.
"""
function GrB_Semiring_new(monoid::Monoid, binary_op::GrB_BinaryOp)
    semiring = Semiring()
    semiring.xtype = binary_op.xtype
    semiring.ytype = binary_op.ytype
    semiring.ztype = binary_op.ztype
    
    semiring_ptr = pointer_from_objref(semiring)

    check(GrB_Info(
            ccall(
                    dlsym(graphblas_lib, "GrB_Semiring_new"),
                    Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    semiring_ptr, monoid.p, binary_op.p
                )
            )
    )
    return semiring
end