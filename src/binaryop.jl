import Base: show

# create new unary op from function fun, called s
function binaryop(s::Symbol, fun::Function; xtype::GType = NULL, ztype::GType = NULL, ytype::GType = NULL)
    bop = get!(Binaryop, s, BinaryOperator(fun, string(s)))
    if xtype != NULL && ztype != NULL && ytype != NULL
        if findfirst(op->op.xtype == xtype && op.ztype == ztype && op.ytype == ytype, bop.impl) == nothing
            op = GrB_BinaryOp_new(fun, ztype, xtype, ytype)
            push!(bop.impl, op)
        end    
    end
    return bop
end

function load_builtin_binaryop()

    function load(lst; ztype = NULL)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype(string(bpn[end]))
            
            binaryop_name = Symbol(join(bpn[2:end - 1]))
            binaryop = get!(Binaryop, binaryop_name, BinaryOperator(string(binaryop_name)))
            push!(binaryop.impl, GrB_BinaryOp(op, ztype == NULL ? type : ztype, type, type))
        end
    end

    grb_bop = compile(["GrB"],
    ["FIRST", "SECOND", "MIN", "MAX", "PLUS", "MINUS", "TIMES", "DIV"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    gxb_bop = compile(["GxB"],
    ["ISEQ", "ISNE", "ISGT", "ISLT", "ISGE", "ISLE", "LOR", "LAND", "LXOR"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    grb_bool = compile(["GrB"],
    ["EQ", "NE", "GT", "LT", "GE", "LE"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    load(cat(grb_bop, gxb_bop, dims = 1))
    load(grb_bool, ztype = BOOL)
    
end

# get GrB_BinaryOp associated at BinaryOperation with a specific input domain type
function _get(binary_op::BinaryOperator, types...)
    ztype, xtype, ytype = types
    index = findfirst(op->op.xtype == xtype && op.ztype == ztype && op.ytype == ytype, binary_op.impl)
    if index == nothing
        if binary_op.fun != nothing
            # user defined binary op
            bop = GrB_BinaryOp_new(binary_op.fun, ztype, xtype, ytype)
            push!(binary_op.impl, bop)
            return bop
        end
    else
        return binary_op.impl[index]
    end
end

function GrB_BinaryOp_new(fn::Function, ztype::GType{T}, xtype::GType{U}, ytype::GType{V}) where {T,U,V}
    op = GrB_BinaryOp()
    op.xtype = xtype
    op.ytype = ytype
    op.ztype = ztype

    op_ptr = pointer_from_objref(op)

    function binaryop_fn(z, x, y)
        unsafe_store!(z, fn(x, y))
        return nothing
    end

    binaryop_fn_C = @cfunction($binaryop_fn, Cvoid, (Ptr{T}, Ref{U}, Ref{V}))

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_BinaryOp_new"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            op_ptr, binaryop_fn_C, _gb_pointer(ztype), _gb_pointer(xtype), _gb_pointer(ytype)
            )
        )
    return op
end

function __enter__(bop::BinaryOperator)
    global g_operators
    old = g_operators.binaryop
    g_operators = Base.setindex(g_operators, bop, :binaryop)
    return (binaryop=old,)
end

show(io::IO, bop::BinaryOperator) = print(io, "BinaryOperator($(bop.name))")