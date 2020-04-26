import Base: getindex, size, copy, lastindex, setindex!, eltype, adjoint, Matrix
    
_gb_pointer(m::GBMatrix) = m.p

function matrix_from_type(type::GType, nrows = 0, ncols = 0)
    m = GBMatrix{type.jtype}()
    GrB_Matrix_new(m, type, nrows, ncols)
    finalizer(_free, m)
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
        type = j2gtype(eltype(V))
    elseif type.jtype != eltype(V)
        V = convert.(type.jtype, V)
    end
    m = matrix_from_type(type, nrows, ncols)

    if combine == NULL
        combine = Binaryop.FIRST
    end
    combine_bop = _get(combine, type, type, type)
    GrB_Matrix_build(m, I, J, V, length(V), combine_bop)
    return m
end

function from_matrix(m)
    r, c = size(m)
    res = matrix_from_type(j2gtype(eltype(m)), r, c)

    i, j = 0, 0
    for v in m
        if !iszero(v)
            res[i, j] = v
        end
        i += 1
        if i >= r
            i = 0
            j += 1
        end
    end
    return res
end

function identity(type, n)
    res = matrix_from_type(type, n, n)
    for i in 0:n-1
        res[i,i] = type.one
    end
    return res
end

function Matrix(A::GBMatrix{T}) where T
    rows, cols = size(A)
    res = Matrix{T}(undef, rows, cols)
    
    for i in 0:rows-1
        for j in 0:cols-1
            res[i+1, j+1] = A[i, j]
        end
    end
    return res
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

setindex!(m::GBMatrix, value, i::Colon, j::Integer) = _assign_col!(m, value, j, _all_rows(m))
setindex!(m::GBMatrix, value, i::Integer, j::Colon) = _assign_row!(m, value, i, _all_cols(m))
setindex!(m::GBMatrix, value, i::Colon, j::Colon) = 
    _assign_matrix!(m, value, _all_rows(m), _all_cols(m))
setindex!(m::GBMatrix, value, i::Union{UnitRange,Vector}, j::Integer) = 
    _assign_col!(m, value, j, collect(i))
setindex!(m::GBMatrix, value, i::Integer, j::Union{UnitRange,Vector}) = 
    _assign_row!(m, value, i, collect(j))
setindex!(m::GBMatrix, value, i::Union{UnitRange,Vector}, j::Union{UnitRange,Vector}) =
    _assign_matrix!(m, value, collect(i), collect(j))
setindex!(m::GBMatrix, value, i::Union{UnitRange,Vector}, j::Colon) =
    _assign_matrix!(m, value, collect(i), _all_cols(m))
setindex!(m::GBMatrix, value, i::Colon, j::Union{UnitRange,Vector}) =
    _assign_matrix!(m, value, _all_rows(m), collect(j))


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

getindex(m::GBMatrix, i::Colon, j::Integer) = _extract_col(m, j, _all_rows(m))
getindex(m::GBMatrix, i::Integer, j::Colon) = _extract_row(m, i, _all_cols(m))
getindex(m::GBMatrix, i::Colon, j::Colon) = copy(m)
getindex(m::GBMatrix, i::Union{UnitRange,Vector}, j::Integer) = _extract_col(m, j, collect(i))
getindex(m::GBMatrix, i::Integer, j::Union{UnitRange,Vector}) = _extract_row(m, i, collect(j))
getindex(m::GBMatrix, i::Union{UnitRange,Vector}, j::Union{UnitRange,Vector}) =
    _extract_matrix(m, collect(i), collect(j))
getindex(m::GBMatrix, i::Union{UnitRange,Vector}, j::Colon) =
    _extract_matrix(m, collect(i), _all_cols(m))
getindex(m::GBMatrix, i::Colon, j::Union{UnitRange,Vector}) =
    _extract_matrix(m, _all_rows(m), collect(j))

_all_rows(m) = collect(0:size(m, 1) - 1)
_all_cols(m) = collect(0:size(m, 2) - 1)

function mxm(A::GBMatrix, B::GBMatrix; out = nothing, semiring = nothing, mask = nothing, accum = nothing, desc = nothing)
    rowA, colA = size(A)
    rowB, colB = size(B)
    @assert colA == rowB

    if out == nothing
        out = matrix_from_type(A.type, rowA, colB)
    end

    if semiring == nothing
        semiring = g_operators.semiring
    end
    semiring_impl = _get(semiring, out.type, A.type, B.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_mxm"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(semiring_impl),
            _gb_pointer(A), _gb_pointer(B), _gb_pointer(desc)
            )
        )
    
    return out
end

function mxv(A::GBMatrix, u::GBVector; out = nothing, semiring = nothing, mask = nothing, accum = nothing, desc = nothing)
    rowA, colA = size(A)
    @assert colA == size(u)

    if out == nothing
        out = vector_from_type(A.type, rowA)
    end

    if semiring == nothing
        semiring = g_operators.semiring
    end
    semiring_impl = _get(semiring, out.type, A.type, u.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_mxv"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(semiring_impl),
            _gb_pointer(A), _gb_pointer(u), _gb_pointer(desc)
            )
        )
    
    return out
end

function emult(A::GBMatrix, B::GBMatrix; out = nothing, operator = nothing, mask = nothing, accum = nothing, desc = nothing)
    # operator: can be binaryop, monoid, semiring
    @assert size(A) == size(B)

    if out == nothing
        out = matrix_from_type(A.type, size(A)...)
    end

    if operator == nothing
        operator = g_operators.binaryop
    end
    operator_impl = _get(operator, out.type, A.type, B.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    suffix = split(string(typeof(operator_impl)), "_")[end]

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_eWiseMult_Matrix_" * suffix),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(operator_impl),
            _gb_pointer(A), _gb_pointer(B), _gb_pointer(desc)
            )
        )
    
    return out
end

function eadd(A::GBMatrix, B::GBMatrix; out = nothing, operator = nothing, mask = nothing, accum = nothing, desc = nothing)
    # operator: can be binaryop, monoid and semiring
    @assert size(A) == size(B)

    if out == nothing
        out = matrix_from_type(A.type, size(A)...)
    end

    if operator == nothing
        operator = g_operators.binaryop
    end
    operator_impl = _get(operator, out.type, A.type, B.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    suffix = split(string(typeof(operator_impl)), "_")[end]

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_eWiseAdd_Matrix_" * suffix),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(operator_impl),
            _gb_pointer(A), _gb_pointer(B), _gb_pointer(desc)
            )
        )
    
    return out
end

function apply(A::GBMatrix; out = nothing, unaryop = nothing, mask = nothing, accum = nothing, desc = nothing)
    if out == nothing
        out = matrix_from_type(A.type, size(A)...)
    end

    if unaryop == nothing
        unaryop = g_operators.unaryop
    end
    unaryop_impl = _get(unaryop, out.type, A.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_apply"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(unaryop_impl),
            _gb_pointer(A), _gb_pointer(desc)
            )
        )
    
    return out
end

function apply!(A::GBMatrix; unaryop = nothing, mask = nothing, accum = nothing, desc = nothing)
    return apply(A, out = A, unaryop = unaryop, mask = mask, accum = accum, desc = desc)
end

# TODO: select

function reduce_vector(A::GBMatrix; out = nothing, operator = nothing, mask = nothing, accum = nothing, desc = nothing)
    # operator: can be binary op or monoid
    if out == nothing
        out = vector_from_type(A.type, size(A, 1))
    end

    if operator == nothing
        operator = g_operators.monoid
    end
    operator_impl = _get(operator, A.type, A.type, A.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    suffix = split(string(typeof(operator_impl)), "_")[end]

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_reduce_" * suffix),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(operator_impl),
            _gb_pointer(A), _gb_pointer(desc)
            )
        )
    
    return out
end

function reduce_scalar(A::GBMatrix{T}; monoid = nothing, accum = nothing, desc = nothing) where T
    if monoid == nothing
        monoid = g_operators.monoid
    end
    monoid_impl = _get(monoid, A.type)

    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    scalar = Ref(T(0))
    
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_reduce_" * suffix(T)),
            Cint,
            (Ptr{T}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            scalar, _gb_pointer(accum), _gb_pointer(monoid_impl), _gb_pointer(A), _gb_pointer(desc)
            )
        )
    
    return scalar[]
end

function transpose(A::GBMatrix; out = nothing, mask = nothing, accum = nothing, desc = nothing)
    if out == nothing
        out = matrix_from_type(A.type, reverse(size(A))...)
    end

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_transpose"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(A), _gb_pointer(desc)
            )
        )
    
    return out
end

adjoint(A::GBMatrix) = transpose(A)

# function transpose!(A::GBMatrix; mask = nothing, accum = nothing, desc = nothing)
#     return transpose(A, out = A, mask = mask, accum = accum, desc = desc)
# end

function kron(A::GBMatrix, B::GBMatrix; out = nothing, binaryop = nothing, mask = nothing, accum = nothing, desc = nothing)
    if out == nothing
        out = matrix_from_type(A.type, size(A) .* size(B)...)
    end

    if binaryop == nothing
        binaryop = g_operators.binaryop
    end
    binaryop_impl = _get(binaryop, out.type, A.type, B.type)

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_kron"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(binaryop_impl),
            _gb_pointer(A), _gb_pointer(B), _gb_pointer(desc)
            )
        )
    
    return out
end

function _extract_col(A::GBMatrix, col, rows::Vector{I}; out = nothing, mask = nothing, accum = nothing, desc = nothing) where I <: Union{UInt64,Int64}
    ni = length(rows)
    @assert ni > 0

    if out == nothing
        out = vector_from_type(A.type, ni)
    end

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL
    
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Col_extract"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{I}, Cuintmax_t, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum),
            _gb_pointer(A), pointer(rows), ni, col, _gb_pointer(desc)
            )
        )
    
    return out
end

function _extract_row(A::GBMatrix, row, cols::Vector{I}; out = nothing, mask = nothing, accum = nothing, desc = nothing) where I <: Union{UInt64,Int64}
    # TODO: rewrite with transpose descriptor
    return _extract_col(A', row, cols, out = out, mask = mask, accum = accum, desc = desc)
end

function _extract_matrix(A::GBMatrix, rows::Vector{I}, cols::Vector{I}; out = nothing, mask = nothing, accum = nothing, desc = nothing) where I <: Union{UInt64,Int64}
    ni, nj = length(rows), length(cols)
    @assert ni > 0 && nj > 0

    if out == nothing
        out = matrix_from_type(A.type, ni, nj)
    end

    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_extract"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{I}, Cuintmax_t, Ptr{I}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(A),
            pointer(rows), ni, pointer(cols), nj, _gb_pointer(desc)
            )
        )
    
    return out
end

function _assign_row!(A::GBMatrix, u::GBVector, row::I, cols::Vector{I}; mask = nothing, accum = nothing, desc = nothing) where I <: Union{UInt64,Int64}
    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Row_subassign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Ptr{Cuintmax_t}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(u),
            row, pointer(cols), length(cols), _gb_pointer(desc)
            )
        )
    
end

function _assign_col!(A::GBMatrix, u::GBVector, col::I, rows::Vector{I}; mask = nothing, accum = nothing, desc = nothing) where I <: Union{UInt64,Int64}
    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Col_subassign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cuintmax_t}, Cuintmax_t, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(u),
            pointer(rows), length(rows), col, _gb_pointer(desc)
            )
        )
    
end

function _assign_matrix!(A::GBMatrix, B::GBMatrix, rows::Vector{I}, cols::Vector{I}; mask = nothing, accum = nothing, desc = nothing) where I <: Union{UInt64,Int64}
    ni, nj = length(rows), length(cols)
    @assert ni > 0 && nj > 0
    
    # TODO: mask
    mask = NULL
    # TODO: accum
    accum = NULL
    # TODO: desc
    desc = NULL

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Matrix_subassign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cuintmax_t}, Cuintmax_t, Ptr{Cuintmax_t}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(B),
            pointer(rows), ni, pointer(cols), nj, _gb_pointer(desc)
            )
        )
end

function _free(A::GBMatrix)
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_free"),
            Cint,
            (Ptr{Cvoid}, ),
            pointer_from_objref(A)
            )
        )
end