import Base: show

# create new unary op from function fun, called s
function unaryop(fun::Function; xtype::GType = NULL, ztype::GType = NULL, name::Union{Symbol, Nothing} = nothing)
    if name != nothing
        if hasproperty(Unaryop, name)
            uop = getproperty(Unaryop, name)
        else
            uop = UnaryOperator(fun, string(name))
            @eval(Unaryop, $name = $uop)
            @eval(Unaryop, export $name)
        end
    else
        uop = UnaryOperator(fun, "$(string(name))_$(ztype.name)")
    end
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
        if hasproperty(Unaryop, unaryop_name)
            unaryop = getproperty(Unaryop, unaryop_name)
        else
            unaryop = UnaryOperator(string(unaryop_name))
            @eval(Unaryop, $unaryop_name = $unaryop)
            @eval(Unaryop, export $unaryop_name)
        end
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

function __enter__(uop::UnaryOperator)
    global g_operators
    old = g_operators.unaryop
    g_operators = Base.setindex(g_operators, uop, :unaryop)
    return (unaryop=old,)
end

show(io::IO, uop::UnaryOperator) = print(io, "UnaryOperator($(uop.name))")

baremodule Unaryop
    # to fill with binary ops built in and user defined
end