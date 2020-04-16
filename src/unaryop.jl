mutable struct GrB_UnaryOp
    p::Ptr{Cvoid}
    fun::Function

    function GrB_UnaryOp(str::String)
        return new(load_global(str))
    end

    function GrB_UnaryOp(fun::Function)
        return new(C_NULL, fun)
    end
    
end

const global_unaryop = Dict{Symbol, Array{GrB_UnaryOp, 1}}()

function unaryop(s::Symbol, fun::Function)
    if haskey(global_unaryop, s)
        error("unary operation already exists")
    else
        push!(global_unaryop, s => [GrB_UnaryOp(fun)])
    end
    nothing
end

function load_builtin_unaryop()
    global global_unaryop

    grb_uop = compile(["GrB"],
    ["IDENTITY", "AINV", "MINV"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    gxb_uop = compile(["GxB"],
    ["ONE", "ABS"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    load_buildin_op(global_unaryop, cat(grb_uop, gxb_uop, dims=1), GrB_UnaryOp)
end