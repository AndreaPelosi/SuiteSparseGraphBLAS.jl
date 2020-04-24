# create new unary op from function fun, called s
function unaryop(s::Symbol, fun::Function; xtype::GType = NULL, ztype::GType = NULL)
    uop = get!(Unaryop, s, UnaryOperator(fun))
    if xtype != NULL && ztype != NULL
        if findfirst(op->op.xtype == xtype && op.ztype == ztype, uop.impl) == nothing
            op = GrB_UnaryOp_new(fun, ztype, xtype)
            push!(uop.impl, op)
        end
    end
    return uop
end

function load_builtin_unaryop()
    grb_uop = compile(["GrB"],
    ["IDENTITY", "AINV", "MINV"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    gxb_uop = compile(["GxB"],
    ["ONE", "ABS", "LNOT"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    for op in cat(grb_uop, gxb_uop, dims = 1)
        opn = split(op, "_")
        type = str2gtype(string(opn[end]))
        
        unaryop_name = Symbol(join(opn[2:end - 1]))
        unaryop = get!(Unaryop, unaryop_name, UnaryOperator())
        push!(unaryop.impl, GrB_UnaryOp(op, type, type))
    end
    
end

# get GrB_UnaryOp associated at UnaryOperator with a specific input domain type
function _get(uop::UnaryOperator, types...)
    ztype, xtype = types
    index = findfirst(op->op.xtype == xtype && op.ztype == ztype, uop.impl)
    if index == nothing
        op = GrB_UnaryOp_new(uop.fun, ztype, xtype)
        push!(uop.impl, op)
        return op
    else
        return uop.impl[index]
    end
end

function GrB_UnaryOp_new(fn::Function, ztype::GType{T}, xtype::GType{U}) where {T,U}

    op = GrB_UnaryOp()
    op.ztype = ztype
    op.xtype = xtype

    op_ptr = pointer_from_objref(op)

    function unaryop_fn(z, x)
        unsafe_store!(z, fn(x))
        return nothing
    end

    unaryop_fn_C = @cfunction($unaryop_fn, Cvoid, (Ptr{T}, Ref{U}))

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_UnaryOp_new"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            op_ptr, unaryop_fn_C, _gb_pointer(ztype), _gb_pointer(xtype)
            )
        )

    return op
end