import Base: getindex, size, copy, lastindex, setindex!, eltype, adjoint, Matrix, identity, kron, transpose,
             show, ==, *, |>

"""
    matrix_from_type(type, m, n)

Create an empty GBMatrix of size m×n from the given type `type`.

"""
function matrix_from_type(type::GType, m, n)
    r = GBMatrix{type.jtype}()
    GrB_Matrix_new(r, type, m, n)
    finalizer(_free, r)
    return r
end

"""
    matrix_from_lists(I, J, V; m = nothing, n = nothing, type = NULL, combine = NULL)

Create a new GBMatrix from the given lists of row indices, column indices and values.
If `m` and `n` are not provided, they are computed from the max values of the row and column indices lists, respectively.
If `type` is not provided, it is inferred from the values list.
A combiner Binary Operator can be provided to manage duplicates values. If it is not provided, the default `BinaryOp.FIRST` is used.

# Arguments
- `I`: the list of row indices.
- `J`: the list of column indices.
- `V`: the list of values.
- `m`: the number of rows.
- `n`: the number of columns.
- `type`: the GBType of the GBMatrix.
- `combine`: the `BinaryOperator` which assembles any duplicate entries with identical indices.

"""
function matrix_from_lists(I, J, V; m = nothing, n = nothing, type = NULL, combine = NULL)
    @assert length(I) == length(J) == length(V)
    if m === nothing
        m = maximum(I)
    end
    if n === nothing
        n = maximum(J)
    end
    if type === NULL
        type = j2gtype(eltype(V))
    elseif type.jtype != eltype(V)
        V = convert.(type.jtype, V)
    end
    m = matrix_from_type(type, m, n)

    if combine === NULL
        combine = Binaryop.FIRST
    end
    combine_bop = _get(combine, type, type, type)
    I = map(x->x - 1, I)
    J = map(x->x - 1, J)
    GrB_Matrix_build(m, I, J, V, length(V), combine_bop)
    return m
end

"""
    from_matrix(m)

Create a GBMatrix from the given Matrix `m`.

"""
function from_matrix(m)
    r, c = size(m)
    res = matrix_from_type(j2gtype(eltype(m)), r, c)

    i, j = 1, 1
    for v in m
        if !iszero(v)
            res[i, j] = v
        end
        i += 1
        if i > r
            i = 1
            j += 1
        end
    end
    return res
end

"""
    identity(type, n)

Create an identity GBMatrix of size n×n with the given type `type`.

"""
function identity(type, n)
    res = matrix_from_type(type, n, n)
    for i in 1:n
        res[i,i] = type.one
    end
    return res
end

"""
    Matrix(A::GBMatrix{T})

Construct a Matrix{T} from a GBMatrix{T} A.

"""
function Matrix(A::GBMatrix{T}) where T
    rows, cols = size(A)
    res = Matrix{T}(undef, rows, cols)
    
    for i in 1:rows
        for j in 1:cols
            res[i, j] = A[i, j]
        end
    end
    return res
end

function show(io::IO, ::MIME"text/plain", M::GBMatrix{T}) where T
    s = size(M)

    print(io, "$(Int64(s[1]))x$(Int64(s[2])) GBMatrix{$(T)} ")
    println(io, "with $(nnz(M)) stored entries:")

    for (i, j, x) in zip(findnz(M)...)
        println("  [$i, $j] = $x")
    end
end

"""
    ==(A, B)

Check if two matrices `A` and `B` are equal.
"""
function ==(A::GBMatrix{T}, B::GBMatrix{U}) where {T,U}
    T != U && return false

    Asize = size(A)
    Anvals = nnz(A)

    Asize == size(B) || return false
    Anvals == nnz(B) || return false

    @with Binaryop.EQ, Monoids.LAND begin
        C = emult(A, B, out = matrix_from_type(BOOL, Asize...))
        eq = reduce_scalar(C)
    end
    
    return eq
end

*(A::GBMatrix, B::GBMatrix) = mxm(A, B)
*(A::GBMatrix, u::GBVector) = mxv(A, u)

broadcasted(::typeof(+), A::GBMatrix, B::GBMatrix) = eadd(A, B)
broadcasted(::typeof(*), A::GBMatrix, B::GBMatrix) = emult(A, B)

|>(A::GBMatrix, op::UnaryOperator) = apply(A, unaryop = op)

"""
    size(m::GBMatrix, [dim])

Return a tuple containing the dimensions of m.
Optionally you can specify a dimension to just get the length of that dimension.

# Examples
```julia-repl
julia> A = from_matrix([1 2 3; 4 5 6]);

julia> size(A)
(2, 3)

julia> size(A, 1)
2
```
"""
function size(m::GBMatrix, dim = nothing)
    if dim === nothing
        return (Int64(GrB_Matrix_nrows(m)), Int64(GrB_Matrix_ncols(m)))
    elseif dim == 1
        return Int64(GrB_Matrix_nrows(m))
    elseif dim == 2
        return Int64(GrB_Matrix_ncols(m))
    else
        error("dimension out of range")
    end
end

"""
    square(m::GBMatrix)

Return true if `m` is a square matrix.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 4 5]);

julia> square(A)
true
```
"""
function square(m::GBMatrix)
    rows, cols = size(m)
    return rows == cols
end

"""
    copy(m::GBMatrix)

Create a copy of m.

"""
function copy(m::GBMatrix)
    cpy = matrix_from_type(m.type, size(m)...)
    GrB_Matrix_dup(cpy, m)
    return cpy
end

"""
    findnz(m::GBMatrix)

Return a tuple `(I, J, V)` where `I` and `J` are the row and column lists of the "non-zero" values in `m`,
and `V` is a list of "non-zero" values.

# Examples
```julia-repl
julia> A = from_matrix([1 2 0; 0 0 1]);

julia> findnz(A)
([1, 1, 2], [1, 2, 3], [1, 2, 1])
```
"""
function findnz(m::GBMatrix)
    I, J, V = GrB_Matrix_extractTuples(m)
    map!(x->x + 1, I, I)
    map!(x->x + 1, J, J)
    return I, J, V
end

"""
    nnz(m::GBMatrix)

Return the number of entries in a matrix `m`.

# Examples
```julia-repl
julia> A = from_matrix([1 2 0; 0 0 1]);

julia> nnz(A)
3
```
"""
function nnz(m::GBMatrix)
    return Int64(GrB_Matrix_nvals(m))
end

"""
    clear!(m::GBMatrix)

Clear all entries from a matrix `m`.

"""
function clear!(m::GBMatrix)
    GrB_Matrix_clear(m)
end

"""
    lastindex(m::GBMatrix, [d])

Return the last index of a matrix `m`. If `d` is given, return the last index of `m` along dimension `d`.

# Examples
```julia-repl
julia> A = from_matrix([1 2 0; 0 0 1]);

julia> lastindex(A)
(2, 3)

julia> lastindex(A, 2)
3
```
"""
function lastindex(m::GBMatrix, d = nothing)
    return size(m, d)
end

function setindex!(m::GBMatrix{T}, value, i::Integer, j::Integer) where T
    value = convert(T, value)
    GrB_Matrix_setElement(m, value, i - 1, j - 1)
end

setindex!(m::GBMatrix, value, i::Colon, j::Integer) = _assign_col!(m, value, j - 1, GrB_ALL)
setindex!(m::GBMatrix, value, i::Integer, j::Colon) = _assign_row!(m, value, i - 1, GrB_ALL)
setindex!(m::GBMatrix, value, i::Colon, j::Colon) = 
    _assign_matrix!(m, value, GrB_ALL, GrB_ALL)
setindex!(m::GBMatrix, value, i::Union{UnitRange,Vector}, j::Integer) = 
    _assign_col!(m, value, j - 1, _zero_based_indexes(i))
setindex!(m::GBMatrix, value, i::Integer, j::Union{UnitRange,Vector}) = 
    _assign_row!(m, value, i - 1, _zero_based_indexes(j))
setindex!(m::GBMatrix, value, i::Union{UnitRange,Vector}, j::Union{UnitRange,Vector}) =
    _assign_matrix!(m, value, _zero_based_indexes(i), _zero_based_indexes(j))
setindex!(m::GBMatrix, value, i::Union{UnitRange,Vector}, j::Colon) =
    _assign_matrix!(m, value, _zero_based_indexes(i), GrB_ALL)
setindex!(m::GBMatrix, value, i::Colon, j::Union{UnitRange,Vector}) =
    _assign_matrix!(m, value, GrB_ALL, _zero_based_indexes(j))


function getindex(m::GBMatrix, i::Integer, j::Integer)
    try
        return GrB_Matrix_extractElement(m, i - 1, j - 1)
    catch e
        if e isa GraphBLASNoValueException
            return m.type.zero
        else
            rethrow(e)
        end
    end
end

getindex(m::GBMatrix, i::Colon, j::Integer) = _extract_col(m, j - 1, GrB_ALL)
getindex(m::GBMatrix, i::Integer, j::Colon) = _extract_row(m, i - 1, GrB_ALL)
getindex(m::GBMatrix, i::Colon, j::Colon) = copy(m)
getindex(m::GBMatrix, i::Union{UnitRange,Vector}, j::Integer) = _extract_col(m, j - 1, _zero_based_indexes(i))
getindex(m::GBMatrix, i::Integer, j::Union{UnitRange,Vector}) = _extract_row(m, i - 1, _zero_based_indexes(j))
getindex(m::GBMatrix, i::Union{UnitRange,Vector}, j::Union{UnitRange,Vector}) =
    _extract_matrix(m, _zero_based_indexes(i), _zero_based_indexes(j))
getindex(m::GBMatrix, i::Union{UnitRange,Vector}, j::Colon) =
    _extract_matrix(m, _zero_based_indexes(i), GrB_ALL)
getindex(m::GBMatrix, i::Colon, j::Union{UnitRange,Vector}) =
    _extract_matrix(m, GrB_ALL, _zero_based_indexes(j))

_zero_based_indexes(i::Vector) = map!(x->x - 1, i, i)
_zero_based_indexes(i::UnitRange) = collect(i .- 1)

"""
    mxm(A::GBMatrix, B::GBMatrix; kwargs...)

Multiply two sparse matrix `A` and `B` using the `semiring`. If a `semiring` is not provided, it uses the default semiring.

# Arguments
- `A`: the first matrix.
- `B`: the second matrix.
- `[out]`: the output matrix for result.
- `[semiring]`: the semiring to use.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask`, `A` and `B`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> B = copy(A);

julia> out = mxm(A, B, semiring = Semirings.PLUS_TIMES)

# TODO: insert output
```
"""
function mxm(A::GBMatrix, B::GBMatrix; kwargs...)
    rowA, colA = size(A)
    rowB, colB = size(B)
    @assert colA == rowB

    out, semiring, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = matrix_from_type(A.type, rowA, colB)
    end

    if semiring === NULL
        semiring = g_operators.semiring
    end
    semiring_impl = _get(semiring, out.type, A.type, B.type)

    if accum !== NULL
        accum = _get(accum)
    end

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

"""
    mxv(A::GBMatrix, u::GBVector; kwargs...) -> GBVector

Multiply a sparse matrix `A` times a column vector `u`.

# Arguments
- `A`: the sparse matrix.
- `u`: the column vector.
- `[out]`: the output vector for result.
- `[semiring]`: the semiring to use.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask`, `A` and `B`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> u = from_vector([1, 2]);

julia> out = mxv(A, u, semiring = Semirings.PLUS_TIMES)

# TODO: insert output
```
"""
function mxv(A::GBMatrix, u::GBVector; kwargs...)
    rowA, colA = size(A)
    @assert colA == size(u)

    out, semiring, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = vector_from_type(A.type, rowA)
    end

    if semiring === NULL
        semiring = g_operators.semiring
    end
    semiring_impl = _get(semiring, out.type, A.type, u.type)
    
    if accum !== NULL
        accum = _get(accum)
    end

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

"""
    emult(A::GBMatrix, B::GBMatrix; kwargs...)

Compute the element-wise "multiplication" of two matrices `A` and `B`, using a `Binary Operator`, a `Monoid` or a `Semiring`.
If given a `Monoid`, the additive operator of the monoid is used as the multiply binary operator.
If given a `Semiring`, the multiply operator of the semiring is used as the multiply binary operator.

# Arguments
- `A`: the first matrix.
- `B`: the second matrix.
- `[out]`: the output matrix for result.
- `[operator]`: the operator to use. Can be either a Binary Operator, or a Monoid or a Semiring.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask`, `A` and `B`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> B = copy(A);

julia> out = emult(A, B, operator = Binaryop.PLUS)

# TODO: insert output
```
"""
function emult(A::GBMatrix, B::GBMatrix; kwargs...)
    # operator: can be binaryop, monoid, semiring
    @assert size(A) == size(B)

    out, operator, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = matrix_from_type(A.type, size(A)...)
    end

    if operator === NULL
        operator = g_operators.binaryop
    end
    operator_impl = _get(operator, out.type, A.type, B.type)

    if accum !== NULL
        accum = _get(accum)
    end

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

"""
    eadd(A::GBMatrix, B::GBMatrix; kwargs...)

Compute the element-wise "addition" of two matrices `A` and `B`, using a `Binary Operator`, a `Monoid` or a `Semiring`.
If given a `Monoid`, the additive operator of the monoid is used as the add binary operator.
If given a `Semiring`, the additive operator of the semiring is used as the add binary operator.

# Arguments
- `A`: the first matrix.
- `B`: the second matrix.
- `[out]`: the output matrix for result.
- `[operator]`: the operator to use. Can be either a Binary Operator, or a Monoid or a Semiring.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask`, `A` and `B`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> B = copy(A);

julia> out = eadd(A, B, operator = Binaryop.PLUS)

# TODO: insert output
```
"""
function eadd(A::GBMatrix, B::GBMatrix; kwargs...)
    # operator: can be binaryop, monoid and semiring
    @assert size(A) == size(B)

    out, operator, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = matrix_from_type(A.type, size(A)...)
    end

    if operator === NULL
        operator = g_operators.binaryop
    end
    operator_impl = _get(operator, out.type, A.type, B.type)

    if accum !== NULL
        accum = _get(accum)
    end

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

"""
    apply(A::GBMatrix; kwargs...)

Apply a `Unary Operator` to the entries of a matrix `A`, creating a new matrix.

# Arguments
- `A`: the sparse matrix.
- `[out]`: the output matrix for result.
- `[unaryop]`: the Unary Operator to use.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([-1 2; -3 -4]);

julia> out = apply(A, unaryop = Unaryop.ABS)

# TODO: insert output
```
"""
function apply(A::GBMatrix; kwargs...)
    out, unaryop, mask, accum, desc = __get_args(kwargs)

    if out === NULL
        out = matrix_from_type(A.type, size(A)...)
    end

    if unaryop === NULL
        unaryop = g_operators.unaryop
    end
    unaryop_impl = _get(unaryop, out.type, A.type)

    if accum !== NULL
        accum = _get(accum)
    end

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

"""
    apply!(A::GBMatrix; kwargs...)

Apply a `Unary Operator` to the entries of a matrix `A`.

# Arguments
- `A`: the sparse matrix.
- `[unaryop]`: the Unary Operator to use.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([-1 2; -3 -4]);

julia> apply!(A, unaryop = Unaryop.ABS)

# TODO: insert output
```
"""
function apply!(A::GBMatrix; kwargs...)
    _, operator, mask, accum, desc = __get_args(kwargs)
    return apply(A, out = A, operator = operator, mask = mask, accum = accum, desc = desc)
end

"""
    select(A::GBMatrix, op::SelectOperator; kwargs...)

Apply a `Select Operator` to the entries of a matrix `A`.

# Arguments
- `A`: the sparse matrix.
- `op`: the `Select Operator` to use.
- `[out]`: the output matrix for result.
- `[thunk]`: optional input for the `Select Operator`.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

# TODO: insert example
```
"""
function select(A::GBMatrix, op::SelectOperator; kwargs...)
    out, thunk, mask, accum, desc = __get_args(kwargs)
    
    if out === NULL
        out = matrix_from_type(A.type, size(A)...)
    end

    if accum === NULL
        accum = _get(accum)
    end
    
    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Matrix_select"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(op),
            _gb_pointer(A), _gb_pointer(thunk), _gb_pointer(desc)
            )
        )
    
    return out
end

"""
    reduce_vector(A::GBMatrix; kwargs...)

Reduce a matrix `A` to a column vector using an operator.
Normally the operator is a `Binary Operator`, in which all the three domains must be the same.
It can be used a `Monoid` as an operator. In both cases the reduction operator must be commutative and associative.

# Arguments
- `A`: the sparse matrix.
- `[out]`: the output matrix for result.
- `[operator]`: reduce operator.
- `[accum]`: optional accumulator.
- `[mask]`: optional mask.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> out = reduce_vector(A, operator = Binaryop.PLUS)

# TODO: insert output
```
"""
function reduce_vector(A::GBMatrix; kwargs...)
    out, operator, mask, accum, desc = __get_args(kwargs)
    
    # operator: can be binary op or monoid
    if out === NULL
        out = vector_from_type(A.type, size(A, 1))
    end

    if operator === NULL
        operator = g_operators.monoid
    end
    operator_impl = _get(operator, A.type, A.type, A.type)

    if accum !== NULL
        accum = _get(accum)
    end

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

"""
    reduce_scalar(A::GBMatrix{T}; kwargs...) -> T

Reduce a matrix `A` to a scalar, using the given `Monoid`.

# Arguments
- `A`: the sparse matrix to reduce.
- `[monoid]`: monoid to do the reduction.
- `[accum]`: optional accumulator.
- `[desc]`: descriptor for `A`.

# Examples
```julia-repl
julia> A = from_matrix([1 2; 3 4]);

julia> out = reduce_scalar(A, monoid = Monoids.PLUS)
10
```
"""
function reduce_scalar(A::GBMatrix{T}; kwargs...) where T
    _, monoid, _, accum, desc = __get_args(kwargs)
    
    if monoid === NULL
        monoid = g_operators.monoid
    end
    monoid_impl = _get(monoid, A.type)

    if accum !== NULL
        accum = _get(accum)
    end
    
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

"""
    transpose(A::GBMatrix; kwargs...)

Transpose a matrix `A`.

# Arguments
- `A`: the sparse matrix to transpose.
- `[out]`: the output matrix for result.
- `[mask]`: optional mask.
- `[accum]`: optional accumulator.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl
julia> A = from_matrix([1 2 3; 4 5 6]);

julia> out = transpose(A)

#TODO: insert output
```
"""
function transpose(A::GBMatrix; kwargs...)
    out, _, mask, accum, desc = __get_args(kwargs)
    
    if out === NULL
        out = matrix_from_type(A.type, reverse(size(A))...)
    end

    if accum !== NULL
        accum = _get(accum)
    end

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

"""
    kron(A::GBMatrix, B::GBMatrix; kwargs...)

Compute the Kronecker product, using the given `Binary Operator`.

# Arguments
- `A`: the first matrix.
- `B`: the second matrix.
- `[out]`: the output matrix for result.
- `[binaryop]`: the `Binary Operator` to use.
- `[mask]`: optional mask.
- `[accum]`: optional accumulator.
- `[desc]`: descriptor for `out`, `mask` and `A`.

# Examples
```julia-repl

#TODO: insert example
```
"""
function kron(A::GBMatrix, B::GBMatrix; kwargs...)
    out, binaryop, mask, accum, desc = __get_args(kwargs)
    
    if out === NULL
        out = matrix_from_type(A.type, size(A) .* size(B)...)
    end

    if binaryop === NULL
        binaryop = g_operators.binaryop
    end
    binaryop_impl = _get(binaryop, out.type, A.type, B.type)

    if accum !== NULL
        accum = _get(accum)
    end

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


function __extract_col__(A::GBMatrix, col, pointer_rows, ni; out = NULL, mask = NULL, accum = NULL, desc = NULL)
    @assert ni > 0

    if out === NULL
        out = vector_from_type(A.type, ni)
    end

    if accum !== NULL
        accum = _get(accum)
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Col_extract"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum),
            _gb_pointer(A), pointer_rows, ni, col, _gb_pointer(desc)
            )
        )
    
    return out
end

function _extract_col(A::GBMatrix, col, rows::GSpecial; out = NULL, mask = NULL, accum = NULL, desc = NULL)
    return __extract_col__(A, col, rows.p, size(A, 1), out = out, mask = mask, accum = accum, desc = desc)
end

function _extract_col(A::GBMatrix, col, rows::Vector{I}; out = NULL, mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    return __extract_col__(A, col, pointer(rows), length(rows), out = out, mask = mask, accum = accum, desc = desc)
end

function _extract_row(A::GBMatrix, row, cols; out = NULL, mask = NULL, accum = NULL)
    tran_descriptor = descriptor(inp0 => tran)
    return _extract_col(A, row, cols, out = out, mask = mask, accum = accum, desc = tran_descriptor)
end

function __extract_matrix__(A::GBMatrix, pointer_rows, pointer_cols, ni, nj; out = NULL, mask = NULL, accum = NULL, desc = NULL)
    @assert ni > 0 && nj > 0

    if out === NULL
        out = matrix_from_type(A.type, ni, nj)
    end

    if accum !== NULL
        accum = _get(accum)
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_extract"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(out), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(A),
            pointer_rows, ni, pointer_cols, nj, _gb_pointer(desc)
            )
        )
    
    return out
end

function _extract_matrix(A::GBMatrix, rows::Vector{I}, cols::Vector{I}; out = NULL, mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    return __extract_matrix__(A, pointer(rows), pointer(cols), length(rows), length(cols), out = out, mask = mask, accum = accum, desc = desc)
end

function _extract_matrix(A::GBMatrix, rows::GSpecial, cols::Vector{I}; out = NULL, mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    return __extract_matrix__(A, rows.p, pointer(cols), size(A, 1), length(cols), out = out, mask = mask, accum = accum, desc = desc)
end

function _extract_matrix(A::GBMatrix, rows::Vector{I}, cols::GSpecial; out = NULL, mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    return __extract_matrix__(A, pointer(rows), cols.p, length(rows), size(A, 2), out = out, mask = mask, accum = accum, desc = desc)
end

function _assign_row!(A::GBMatrix, u::GBVector, row::I, cols::Union{Vector{I},GSpecial}; mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}    
    if accum !== NULL
        accum = _get(accum)
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Row_subassign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(u),
            row, pointer(cols), length(cols), _gb_pointer(desc)
            )
        )
    nothing
end

function _assign_col!(A::GBMatrix, u::GBVector, col::I, rows::Union{Vector{I},GSpecial}; mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    if accum !== NULL
        accum = _get(accum)
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Col_subassign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cuintmax_t}, Cuintmax_t, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(u),
            pointer(rows), length(rows), col, _gb_pointer(desc)
            )
        )
    nothing
end

function _assign_matrix!(A::GBMatrix, B::GBMatrix, rows::Union{Vector{I},GSpecial}, cols::Union{Vector{I},GSpecial}; mask = NULL, accum = NULL, desc = NULL) where I <: Union{UInt64,Int64}
    if accum !== NULL
        accum = _get(accum)
    end

    check(
        ccall(
            dlsym(graphblas_lib, "GxB_Matrix_subassign"),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}, Cuintmax_t, Ptr{Cvoid}),
            _gb_pointer(A), _gb_pointer(mask), _gb_pointer(accum), _gb_pointer(B),
            pointer(rows), length(rows), pointer(cols), length(cols), _gb_pointer(desc)
            )
        )
    nothing
end

function _free(A::GBMatrix)
    check(
        ccall(
            dlsym(graphblas_lib, "GrB_Matrix_free"),
            Cint,
            (Ptr{Cvoid},),
            pointer_from_objref(A)
            )
)
end
  
_gb_pointer(m::GBMatrix) = m.p
