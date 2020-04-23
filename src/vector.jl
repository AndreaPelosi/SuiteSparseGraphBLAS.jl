import Base: size, copy, lastindex, setindex!, getindex

mutable struct GBVector{T <: valid_types}
    p::Ptr{Cvoid}
    type::GType
    
    GBVector{T}() where T = new(C_NULL, j2gtype(T))
end

_gb_pointer(m::GBVector) = m.p

function vector_from_type(type, size = 0)
    v = GBVector{type.jtype}()
    GrB_Vector_new(v, type, size)
    # TODO: add finalizer
    return v
end

function vector_from_lists(I, V; size = nothing, type = NULL, combine = NULL)
    @assert length(I) == length(V) 
    if size == nothing
        size = max(I...) + 1
    end
    if type == NULL
        type = j2gtype(eltype(V[1]))
    elseif type.jtype != eltype(V[1])
        V = convert.(type.jtype, V)
    end

    if combine == NULL
        combine = Binaryop.FIRST
    end
    combine_bop = get_binaryop(combine, type, type, type)
    
    v = vector_from_type(type, size)
    GrB_Vector_build(v, I, V, length(V), combine_bop)
    # TODO: add finalizer
    return v
end

function from_vector(V)
    size = length(V)
    @assert size > 0
    return vector_from_lists(collect(0:size-1), V, size=size)
end

function size(v::GBVector)
    return Int64(GrB_Vector_size(v))
end

function nnz(v::GBVector)
    return Int64(GrB_Vector_nvals(v))
end

function findnz(v::GBVector)
    return GrB_Vector_extractTuples(v)
end

function copy(v::GBVector)
    cpy = vector_from_type(v.type, size(v))
    GrB_Vector_dup(cpy, v)
    return cpy
end

function clear!(v::GBVector)
    GrB_Vector_clear(v)
end

function lastindex(v::GBVector, d=nothing)
    return size(v) - 1
end

function setindex!(v::GBVector{T}, value, i::Integer) where T
    value = convert(T, value)
    GrB_Vector_setElement(v, value, i)
end

function getindex(v::GBVector, i::Integer)
    try
        return GrB_Vector_extractElement(v, i)
    catch e
        if e isa GraphBLASNoValueException
            return v.type.zero
        else
            rethrow(e)
        end
    end
end


