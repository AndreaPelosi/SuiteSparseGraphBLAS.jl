import Base: show

function semiring(s::Symbol, add::Monoid, mult::BinaryOperator)
    sem = get!(Semirings, s, Semiring(add, mult, string(s)))
    return sem
end

function _get(semiring::Semiring, types...)
    ztype, xtype, ytype = types
    index = findfirst(sem -> sem.xtype == xtype && sem.ytype == ytype && sem.ztype == ztype, semiring.impl)
    if index == nothing
        # create a semiring with given types
        if semiring.monoid != nothing && semiring.binaryop != nothing
            # user defined semiring
            bop = _get(semiring.binaryop, ztype, xtype, ytype)
            mon = _get(semiring.monoid, ztype)

            sem = GrB_Semiring_new(mon, bop)
            push!(semiring.impl, sem)
            return sem
        end
    else
        return semiring.impl[index]
    end
    error("error")
end

function load_builtin_semiring()

    function load(lst; ztype = NULL)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype(string(bpn[end]))
            
            semiring_name = Symbol(join(bpn[2:end-1], "_"))
            semiring = get!(Semirings, semiring_name, Semiring(string(semiring_name)))
            push!(semiring.impl, GrB_Semiring(op, type, type, ztype == NULL ? type : ztype))
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
function GrB_Semiring_new(monoid::GrB_Monoid, binary_op::GrB_BinaryOp)
    semiring = GrB_Semiring()
    semiring.xtype = binary_op.xtype
    semiring.ytype = binary_op.ytype
    semiring.ztype = binary_op.ztype
    
    semiring_ptr = pointer_from_objref(semiring)

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Semiring_new"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            semiring_ptr, _gb_pointer(monoid), _gb_pointer(binary_op)
            )
        )
    return semiring
end

function __enter__(sem::Semiring)
    global g_operators
    old = g_operators.semiring
    g_operators = Base.setindex(g_operators, sem, :semiring)
    return (semiring=old,)
end

show(io::IO, sem::Semiring) = print(io, "Semiring($(sem.name))")