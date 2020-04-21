Base.push!(up::BinaryOperator, items...) = push!(up.gb_bops, items...)

# create new unary op from function fun, called s
function binaryop(s::Symbol, fun::Function; xtype::GType = NULL, ztype::GType = NULL, ytype::GType = NULL)
    bop = get!(Binaryop, s, BinaryOperator(fun))
    if xtype != NULL && ztype != NULL && ytype != NULL
        if findfirst(op->op.xtype == xtype && op.ztype == ztype && op.ytype == ytype, bop.gb_bops) == nothing
            op = GrB_BinaryOp_new(fun, ztype, xtype, ytype)
            push!(bop, op)
        else
            error("binaryop already exists")
        end    
    end
    nothing
end

function load_builtin_binaryop()

    function load(lst; ztype = NULL)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype(string(bpn[end]))
            
            binaryop_name = Symbol(join(bpn[2:end - 1]))
            binaryop = get!(Binaryop, binaryop_name, BinaryOperator())
            push!(binaryop, GrB_BinaryOp(op, ztype == NULL ? type : ztype, type, type))
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

# get GrB_UnaryOp associated at UnaryOperation with a specific input domain type
function get_binaryop(bop::BinaryOperator, xtype::GType, ztype::GType, ytype::GType)
    index = findfirst(op->op.xtype == xtype && op.ztype == ztype && op.ytype == ytype, bop.gb_bops)
    if index == nothing
        # TODO: try to create new unary op with specified domains
        error("TODO")
    else
        return bop.gb_bops[index]
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

    check(GrB_Info(
            ccall(
                    dlsym(graphblas_lib, "GrB_BinaryOp_new"),
                    Cint,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                    op_ptr, binaryop_fn_C, ztype.gbtype, xtype.gbtype, ytype.gbtype
                )
            ))
    return op
end