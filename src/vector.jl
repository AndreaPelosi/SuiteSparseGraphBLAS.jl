import Base: size, copy, lastindex, setindex!, getindex

_gb_pointer(m::GBVector) = m.p

function vector_from_type(type, size = 0)
    v = GBVector{type.jtype}()
    GrB_Vector_new(v, type, size)
    finalizer(_free, v)
    return v
end

function vector_from_lists(I, V; size = nothing, type = NULL, combine = NULL)
    @assert length(I) == length(V) 
    if size == nothing
        size = max(I...)
    end
    if type == NULL
        type = j2gtype(eltype(V))
    elseif type.jtype != eltype(V)
        V = convert.(type.jtype, V)
    end

    if combine == NULL
        combine = Binaryop.FIRST
    end
    combine_bop = _get(combine, type, type, type)
    map!(x -> x-1, I, I)
    v = vector_from_type(type, size)
    GrB_Vector_build(v, I, V, length(V), combine_bop)
    return v
end

function from_vector(V)
    size = length(V)
    @assert size > 0
    res = vector_from_type(j2gtype(eltype(V)), size)
    
    for (i,v) in enumerate(V)
        if !iszero(V[i])
            res[i] = V[i]
        end
    end
    return res
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

function lastindex(v::GBVector, d = nothing)
    return size(v)
end

function setindex!(v::GBVector{T}, value, i::Integer) where T
    value = convert(T, value)
    GrB_Vector_setElement(v, value, i-1)
end

setindex!(v::GBVector, value, i::Union{UnitRange,Vector}) = _assign!(v, value, _zero_based_indexes(i))
setindex!(v::GBVector, value, i::Colon) = _assign!(v, value, _all_indices(v))

_all_indices(v::GBVector) = collect(0:size(v)-1)

function getindex(v::GBVector, i::Integer)
    try
        return GrB_Vector_extractElement(v, i-1)
    catch e
        if e isa GraphBLASNoValueException
            return v.type.zero
        else
            rethrow(e)
        end
    end
end

getindex(v::GBVector, i::Union{UnitRange,Vector}) = _extract(v, _zero_based_indexes(i))
getindex(v::GBVector, i::Colon) = copy(v)


function emult(u::GBVector, v::GBVector; out = nothing, operator = nothing, mask = nothing, accum = nothing, desc = nothing)
    # operator: can be binary op, monoid and semiring
    if out == nothing
        out = vector_from_type(u.type, size(u))
    end

    if operator == nothing
        operator = g_operators.binaryop
    end
    operator_impl = _get(operator, out.type, u.type, v.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    suffix = split(string(typeof(operator_impl)), "_")[end]

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_eWiseMult_Vector_" * suffix),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(operator_impl),
            _gb_pointer(u), _gb_pointer(v), _gb_pointer(desc)
            )
        )

    return out
end

function eadd(u::GBVector, v::GBVector; out = nothing, operator = nothing, mask = nothing, accum = nothing, desc = nothing)
    # operator: can be binary op, monoid and semiring
    if out == nothing
        out = vector_from_type(u.type, size(u))
    end

    if operator == nothing
        operator = g_operators.binaryop
    end
    operator_impl = _get(operator, out.type, u.type, v.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    suffix = split(string(typeof(operator_impl)), "_")[end]

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_eWiseAdd_Vector_" * suffix),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(operator_impl),
            _gb_pointer(u), _gb_pointer(v), _gb_pointer(desc)
            )
        )

    return out
end

function vxm(u::GBVector, A::GBMatrix; out = nothing, semiring = nothing, mask = nothing, accum = nothing, desc = nothing)
    rowA, colA = size(A)
    @assert size(u) == rowA

    if out == nothing
        out = vector_from_type(u.type, colA)
    end

    if semiring == nothing
        semiring = g_operators.semiring
    end
    semiring_impl = _get(semiring, out.type, u.type, A.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL
    
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_vxm"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(semiring_impl),
            _gb_pointer(u), _gb_pointer(A), _gb_pointer(desc)
            )
        )
    
    return out
end

function apply(u::GBVector; out = nothing, unaryop = nothing, mask = nothing, accum = nothing, desc = nothing)
    if out == nothing
        out = vector_from_type(u.type, size(u))
    end

    if unaryop == nothing
        unaryop = g_operators.unaryop
    end
    unaryop_impl = _get(unaryop, out.type, u.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_apply"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(unaryop_impl),
            _gb_pointer(u), _gb_pointer(desc)
            )
        )

    return out
end

function apply!(u::GBVector; unaryop = nothing, mask = nothing, accum = nothing, desc = nothing)
    return apply(u, out = u, unaryop = unaryop, mask = mask, accum = accum, desc = desc)
end

# TODO: select

function reduce(u::GBVector{T}; monoid = nothing, accum = nothing, desc = nothing) where T
    if monoid == nothing
        monoid = g_operators.monoid
    end
    monoid_impl = _get(monoid, u.type)

    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    scalar = Ref(T(0))

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_reduce_" * suffix(T)),
            Cint,
            (Ptr{T}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            scalar, _gb_pointer(accum), _gb_pointer(monoid_impl), _gb_pointer(u), _gb_pointer(desc)
            )
        )

    return scalar[]
end

function _extract(u::GBVector, indices::Vector{I}; out = nothing, mask = nothing, accum = nothing, desc = nothing) where I <: Union{UInt64,Int64}
    ni = length(indices)
    @assert ni > 0

    if out == nothing
        out = vector_from_type(u.type, ni)
    end

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_extract"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{I}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(u),
            pointer(indices), ni, _gb_pointer(desc)
            )
        )

    return out
end

function _assign!(u::GBVector, v::GBVector, indices::Vector{I}; mask = nothing, accum = nothing, desc = nothing) where I <: Union{UInt64,Int64}
    ni = length(indices)
    @assert ni > 0

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL
    
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_assign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cintmax_t}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(u), _gb_pointer(mask), _gb_pointer(accum),
            _gb_pointer(v), pointer(indices), ni, _gb_pointer(desc)
            )
        )
        
end

function _free(v::GBVector)
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Vector_free"),
            Cint,
            (Ptr{Cvoid}, ),
            pointer_from_objref(v)
            )
        )
end
