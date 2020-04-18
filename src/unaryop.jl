mutable struct GrB_UnaryOp
    p::Ptr{Cvoid}
    ztype::GType
    xtype::GType

    GrB_UnaryOp(name::String, ztype, xtype) = new(load_global(name), ztype, xtype)
    GrB_UnaryOp() = new()
end

# represent a unary operation without assigned type
mutable struct UnaryOperation
    fun::Function
    gb_uops::Array{GrB_UnaryOp,1}

    UnaryOperation(fun) = new(fun, [])

    function UnaryOperation()
        op = new()
        op.gb_uops = []
        return op
    end
end

Base.push!(up::UnaryOperation, items...) = push!(up.gb_uops, items...)

const Unaryop = Dict{Symbol,UnaryOperation}()

# create new unary op from function fun, called s
function unaryop(s::Symbol, fun::Function; xtype::GType = ALL, ztype::GType = ALL)
    if haskey(Unaryop, s)
        if xtype == ALL && ztype == ALL
            error("unaryop already exists")
        end
    else
        uop = UnaryOperation(fun)
        if xtype != ALL && xtype != ALL
            # TODO: create a new GrB_UnaryOp with specified domains
        end
        push!(Unaryop, s => uop)
    end
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
        unaryop = get!(Unaryop, unaryop_name, UnaryOperation())
        push!(unaryop, GrB_UnaryOp(op, type, type))
    end
    
end

# get GrB_UnaryOp associated at UnaryOperation with a specific input domain type
function get_unaryop(uop::UnaryOperation, xtype::GType, ztype::GType)
    index = findfirst(op -> op.xtype == xtype && op.ztype == ztype, uop.gb_uops)
    if index == nothing
        # TODO: try to create new unary op with specified domains
    else
        return uop.gb_uops[index]
    end
end

function Base.getproperty(d::Dict{Symbol,UnaryOperation}, s::Symbol)
    try
        return getfield(d, s)
    catch
        return d[s]
    end
end