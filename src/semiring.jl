mutable struct GrB_Semiring
    p::Ptr{Cvoid}
    xtype::GType    # type of matrix A
    ytype::GType    # type of matrix B
    ztype::GType    # type of result z = fmult(x, y) -> matches with monoid type

    GrB_Semiring() = new()
    GrB_Semiring(s, xtype, ytype, ztype) = new(load_global(s), xtype, ytype, ztype)
end

mutable struct Semiring
    impl::Array{GrB_Semiring, 1}

    Semiring() = new([])
end

function semiring(s::Symbol, sum::Monoid, mult::BinaryOperation)
    # TODO
    error("TODO")
end

const Semirings = Dict{Symbol,Semiring}()

Base.push!(m::Semiring, items...) = push!(m.impl, items...)

function load_builtin_semiring()

    function load(lst; ztype=NULL)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype(string(bpn[end]))
            
            semiring_name = Symbol(join(bpn[2:end - 1], "_"))
            semiring = get!(Semirings, semiring_name, Semiring())
            push!(semiring, GrB_Semiring(op, type, type, type == NULL ? type : ztype))
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

function Base.getproperty(d::Dict{Symbol,Semiring}, s::Symbol)
    try
        return getfield(d, s)
    catch
        return d[s]
    end
end