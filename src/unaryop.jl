mutable struct GrB_UnaryOp
    p::Ptr{Cvoid}
    str::String

    function GrB_UnaryOp(str::String)
        return new(load_global(str), str)
    end
end

global_unaryop = Dict{Symbol, Array{GrB_UnaryOp, 1}}()

grb_uop = compile(["GrB"],
        ["IDENTITY", "AINV", "MINV"],
        ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

gxb_uop = compile(["GxB"],
        ["ONE", "ABS"],
        ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

load_buildin_op(global_unaryop, cat(grb_uop, gxb_uop, dims=1), GrB_UnaryOp)
