mutable struct GrB_UnaryOp
    p::Ptr{Cvoid}
    ztype::GType
    xtype::GType

    GrB_UnaryOp(unaryop_name, ztype, xtype) = new(load_global(unaryop_name), ztype, xtype)
    GrB_UnaryOp() = new()
end

mutable struct GrB_BinaryOp
    p::Ptr{Cvoid}
    ztype::GType
    xtype::GType
    ytype::GType

    GrB_BinaryOp() = new(C_NULL, NULL, NULL, NULL)
    GrB_BinaryOp(binaryop_name, ztype, xtype, ytype) = new(load_global(binaryop_name), ztype, xtype, ytype)
end

mutable struct GrB_Monoid
    p::Ptr{Cvoid}
    domain::GType

    GrB_Monoid() = new(C_NULL, NULL)
    GrB_Monoid(monoid_name, domain) = new(load_global(monoid_name), domain)
end

mutable struct GrB_Semiring
    p::Ptr{Cvoid}
    xtype::GType
    ytype::GType
    ztype::GType

    GrB_Semiring() = new(C_NULL, NULL, NULL, NULL)
    GrB_Semiring(semiring_name, xtype, ytype, ztype) = new(load_global(semiring_name), xtype, ytype, ztype)
end

# represent a unary operation without assigned type
mutable struct UnaryOperator
    fun::Union{Function,Nothing}
    name::String
    impl::Vector{GrB_UnaryOp}

    UnaryOperator(name) = new(nothing, name, [])
    UnaryOperator(fun, name) = new(fun, name, [])
end

mutable struct BinaryOperator
    fun::Union{Function,Nothing}
    name::String
    impl::Vector{GrB_BinaryOp}

    BinaryOperator(name) = new(nothing, name, [])
    BinaryOperator(fun, name) = new(fun, name, [])
end

mutable struct Monoid
    impl::Vector{GrB_Monoid}
    name::String

    Monoid(name) = new([], name)
end

mutable struct Semiring
    monoid::Union{Monoid,Nothing}
    binaryop::Union{BinaryOperator,Nothing}
    name::String
    impl::Vector{GrB_Semiring}

    Semiring(name) = new(nothing, nothing, name, [])
    Semiring(monoid, binaryop, name) = new(monoid, binaryop, name, [])
end

mutable struct SelectOperator
    p::Ptr{Cvoid}
    name::String

    SelectOperator(ref, name) = new(load_global(ref), name)
end

mutable struct GBVector{T <: valid_types}
    p::Ptr{Cvoid}
    type::GType

    GBVector{T}() where T = new(C_NULL, j2gtype(T))
end

mutable struct GBMatrix{T <: valid_types}
    p::Ptr{Cvoid}
    type::GType

    GBMatrix{T}() where T = new(C_NULL, j2gtype(T))
end

function Base.getproperty(d::Dict{Symbol,T}, s::Symbol) where T <: Union{UnaryOperator,BinaryOperator,Monoid,Semiring,SelectOperator}
    try
        return getfield(d, s)
    catch
        return d[s]
    end
end

_gb_pointer(op::GrB_UnaryOp) = op.p
_gb_pointer(op::GrB_BinaryOp) = op.p
_gb_pointer(op::GrB_Monoid) = op.p
_gb_pointer(op::GrB_Semiring) = op.p
_gb_pointer(op::SelectOperator) = op.p

# global variables
const Unaryop = Dict{Symbol,UnaryOperator}()
const Binaryop = Dict{Symbol,BinaryOperator}()
const Monoids = Dict{Symbol,Monoid}()
const Semirings = Dict{Symbol,Semiring}()
const Selectop = Dict{Symbol, SelectOperator}()

# default methods operators
g_operators = nothing