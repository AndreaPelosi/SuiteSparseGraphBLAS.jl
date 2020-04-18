mutable struct GrB_BinaryOp
    p::Ptr{Cvoid}
    ztype::GType
    xtype::GType
    ytype::GType

    GrB_BinaryOp(name::String, ztype, xtype, ytype) = new(load_global(name), ztype, xtype, ytype)
    GrB_BinaryOp() = new()
end

mutable struct BinaryOperation
    fun::Function
    gb_uops::Array{GrB_BinaryOp,1}

    BinaryOperation(fun) = new(fun, [])

    function BinaryOperation()
        op = new()
        op.gb_uops = []
        return op
    end
end

Base.push!(up::BinaryOperation, items...) = push!(up.gb_uops, items...)

const Binaryop = Dict{Symbol,BinaryOperation}()

# create new unary op from function fun, called s
function binaryop(s::Symbol, fun::Function; xtype::GType = ALL, ztype::GType = ALL, ytype::GType = ALL)
    uop = get!(Unaryop, s, BinaryOperation(fun))
    if xtype != ALL && ztype != ALL
        if findfirst(op->op.xtype == xtype && op.ztype == ztype && op.ytype == ytype, uop.gb_uops) == nothing
            op = GrB_BinaryOp_new(fun, ztype, xtype)
            push!(uop, op)
        else
            error("binaryop already exists")
        end
    end
    nothing
end

function load_builtin_binaryop()
    grb_bop = compile(["GrB"],
    ["FIRST", "SECOND", "MIN", "MAX", "PLUS", "MINUS", "TIMES", "DIV"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    gxb_bop = compile(["GxB"],
    ["ISEQ", "ISNE", "ISGT", "ISLT", "ISGE", "ISLE", "LOR", "LAND", "LXOR"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    for op in cat(grb_bop, gxb_bop, dims = 1)
        bpn = split(op, "_")
        type = str2gtype(string(bpn[end]))
        
        binaryop_name = Symbol(join(bpn[2:end - 1]))
        binaryop = get!(Binaryop, binaryop_name, BinaryOperation())
        push!(binaryop, GrB_BinaryOp(op, type, type, type))
    end
    
end

# get GrB_UnaryOp associated at UnaryOperation with a specific input domain type
function get_binaryop(uop::UnaryOperation, xtype::GType, ztype::GType, ytype::GType)
    index = findfirst(op->op.xtype == xtype && op.ztype == ztype && op.ytype == ytype, uop.gb_uops)
    if index == nothing
        # TODO: try to create new unary op with specified domains
    else
        return uop.gb_uops[index]
    end
end

function Base.getproperty(d::Dict{Symbol,BinaryOperation}, s::Symbol)
    try
        return getfield(d, s)
    catch
        return d[s]
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