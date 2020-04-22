import Base: getindex, size, copy, lastindex, setindex!, getindex

mutable struct GBMatrix{T <: valid_types}
    p::Ptr{Cvoid}
    type::GType

    GBMatrix{T}() where T = new(C_NULL, j2gtype(T))
end

_gb_pointer(m::GBMatrix) = m.p

function matrix_from_type(type::GType, nrows = 0, ncols = 0)
    m = GBMatrix{type.jtype}()
    GrB_Matrix_new(m, type, nrows, ncols)
    # TODO: add finalizer
    return m
end

function matrix_from_lists(I, J, V; nrows = nothing, ncols = nothing, type = NULL, combine = NULL)
    @assert length(I) == length(J) == length(V)
    if nrows == nothing
        nrows = max(I...) + 1
    end
    if ncols == nothing
        ncols = max(J...) + 1
    end
    if type == NULL
        type = j2gtype(eltype(V[1]))
    elseif type.jtype != eltype(V[1])
        V = convert.(type.jtype, V)
    end
    m = matrix_from_type(type, nrows, ncols)

    if combine == NULL
        combine = Binaryop.FIRST
    end
    combine_bop = get_binaryop(combine, type, type, type)
    GrB_Matrix_build(m, I, J, V, length(V), combine_bop)
    # TODO: add finalizer
    return m
end

function from_matrix(m)
    # TODO
end

function identity(type, nrows)
    # TODO
end

function size(m::GBMatrix, dim = nothing)
    if dim == nothing
        return (Int64(GrB_Matrix_nrows(m)), Int64(GrB_Matrix_ncols(m)))
    elseif dim == 1
        return Int64(GrB_Matrix_nrows(m))
    elseif dim == 2
        return Int64(GrB_Matrix_ncols(m))
    else
        error("dimension out of range")
    end
end

function square(m::GBMatrix)
    rows, cols = size(m)
    return rows == cols
end

function copy(m::GBMatrix)
    cpy = matrix_from_type(m.type, size(m)...)
    GrB_Matrix_dup(cpy, m)
    return cpy
end

function findnz(m::GBMatrix)
    return GrB_Matrix_extractTuples(m)
end

function nnz(m::GBMatrix)
    return Int64(GrB_Matrix_nvals(m))
end

function clear!(m::GBMatrix)
    GrB_Matrix_clear(m)
end

function lastindex(m::GBMatrix, d = nothing)
    return size(m, d) .- 1
end

function setindex!(m::GBMatrix{T}, value, i::Integer, j::Integer) where T
    value = convert(T, value)
    GrB_Matrix_setElement(m, value, i, j)
end

function setindex!(m::GBMatrix{T}, value, i::Colon, j::Integer) where T
    # TODO: with GBVector
end

function setindex!(m::GBMatrix{T}, value, i::Integer, j::Colon) where T
    # TODO: with GBVector
end

function setindex!(m::GBMatrix{T}, value, i::Colon, j::Colon) where T
    # TODO: with GBVector
end

function getindex(m::GBMatrix, i::Integer, j::Integer)
    try
        return GrB_Matrix_extractElement(m, i, j)
    catch e
        if e isa GraphBLASNoValueException
            return m.type.zero
        else
            rethrow(e)
        end
    end
end

function getindex(m::GBMatrix, i::Colon, j::Integer)
    # TODO: with GBVector
end

function getindex(m::GBMatrix, i::Integer, j::Colon)
    # TODO: with GBVector
end

getindex(m::GBMatrix, i::Colon, j::Colon) = copy(m)

function mxm(A::GBMatrix, B::GBMatrix; out = nothing, semiring = nothing, mask = nothing, accum = nothing, desc = nothing)
    rowA, colA = size(A)
    rowB, colB = size(B)
    @assert colA == rowB

    if out == nothing
        out = matrix_from_type(A.type, rowA, colB)
    end

    if semiring == nothing
        # use default semiring
    end
    semiring_impl = get_semiring(semiring, out.type, A.type, B.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(GrB_Info(
        ccall(
            dlsym(graphblas_lib, "GrB_mxm"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(semiring_impl),
            _gb_pointer(A), _gb_pointer(B), _gb_pointer(desc)
            )
        )
    )
    return out
end

function vxm()
    # TODO
end

function mxv()
    #TODO
end

