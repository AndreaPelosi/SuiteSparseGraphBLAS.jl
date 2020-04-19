Base.push!(up::UnaryOperator, items...) = push!(up.gb_uops, items...)

# create new unary op from function fun, called s
function unaryop(s::Symbol, fun::Function; xtype::GType = NULL, ztype::GType = NULL)
    uop = get!(Unaryop, s, UnaryOperator(fun))
    if xtype != NULL && ztype != NULL
        if findfirst(op->op.xtype == xtype && op.ztype == ztype, uop.gb_uops) == nothing
            op = GrB_UnaryOp_new(fun, ztype, xtype)
            push!(uop, op)
        else
            error("unaryop already exists")
        end
    end
    nothing
end

function load_builtin_unaryop()
    grb_uop = compile(["GrB"],
    ["IDENTITY", "AINV", "MINV"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    gxb_uop = compile(["GxB"],
    ["ONE", "ABS"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    for op in cat(grb_uop, gxb_uop, dims = 1)
        opn = split(op, "_")
        type = str2gtype(string(opn[end]))
        
        unaryop_name = Symbol(join(opn[2:end - 1]))
        unaryop = get!(Unaryop, unaryop_name, UnaryOperator())
        push!(unaryop, GrB_UnaryOp(op, type, type))
    end
    
end

# get GrB_UnaryOp associated at UnaryOperator with a specific input domain type
function get_unaryop(uop::UnaryOperator, xtype::GType, ztype::GType)
    index = findfirst(op->op.xtype == xtype && op.ztype == ztype, uop.gb_uops)
    if index == nothing
        # TODO: try to create new unary op with specified domains
    else
        return uop.gb_uops[index]
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

    check(GrB_Info(ccall(dlsym(graphblas_lib, "GrB_UnaryOp_new"), Cint,
                   (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                   op_ptr, unaryop_fn_C, ztype.gbtype, xtype.gbtype)))

    return op
end