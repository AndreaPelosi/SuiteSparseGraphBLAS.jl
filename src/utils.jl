struct GraphBLASNoValueException <: Exception end
struct GraphBLASUninitializedObjectException <: Exception end
struct GraphBLASInvalidObjectException <: Exception end
struct GraphBLASNullPointerException <: Exception end
struct GraphBLASInvalidValueException <: Exception end
struct GraphBLASInvalidIndexException <: Exception end
struct GraphBLASDomainMismatchException <: Exception end
struct GraphBLASDimensionMismatchException <: Exception end
struct GraphBLASOutputNotEmptyException <: Exception end
struct GraphBLASOutOfMemoryException <: Exception end
struct GraphBLASInsufficientSpaceException <: Exception end
struct GraphBLASIndexOutOfBoundException <: Exception end
struct GraphBLASPanicException <: Exception end

function compile(lst...)
    res = String[]
    if length(lst) == 1
        return lst[1]
    else
        r = compile(lst[2:end]...)
        for e in r
            for l in lst[1]
                push!(res, "$(l)_$(e)")
            end
        end
        return res
    end
end

@enum GrB_Info begin
    GrB_SUCCESS = 0                 # all is well
    GrB_NO_VALUE = 1                # A(ij) requested but not there
    GrB_UNINITIALIZED_OBJECT = 2    # object has not been initialized
    GrB_INVALID_OBJECT = 3          # object is corrupted
    GrB_NULL_POINTER = 4            # input pointer is NULL
    GrB_INVALID_VALUE = 5           # generic error code; some value is bad
    GrB_INVALID_INDEX = 6           # a row or column index is out of bounds
    GrB_DOMAIN_MISMATCH = 7         # object domains are not compatible
    GrB_DIMENSION_MISMATCH = 8      # matrix dimensions do not match
    GrB_OUTPUT_NOT_EMPTY = 9        # output matrix already has values in it
    GrB_OUT_OF_MEMORY = 10          # out of memory
    GrB_INSUFFICIENT_SPACE = 11     # output array not large enough
    GrB_INDEX_OUT_OF_BOUNDS = 12    # a row or column index is out of bounds
    GrB_PANIC = 13                  # SuiteSparse:GraphBLAS only panics if a critical section fails
end

function check(info)
    if info == GrB_NO_VALUE
        throw(GraphBLASNoValueException())
    elseif info == GrB_UNINITIALIZED_OBJECT
        throw(GraphBLASUninitializedObjectException())
    elseif info == GrB_INVALID_OBJECT
        throw(GraphBLASInvalidObjectException())
    elseif info == GrB_NULL_POINTER
        throw(GraphBLASNullPointerException())
    elseif info == GrB_INVALID_VALUE
        throw(GraphBLASInvalidValueException())
    elseif info == GrB_INVALID_INDEX
        throw(GraphBLASInvalidIndexException())
    elseif info == GrB_DOMAIN_MISMATCH
        throw(GraphBLASDomainMismatchException())
    elseif info == GrB_DIMENSION_MISMATCH
        throw(GraphBLASDimensionMismatchException())
    elseif info == GrB_OUTPUT_NOT_EMPTY
        throw(GraphBLASOutputNotEmptyException())
    elseif info == GrB_OUT_OF_MEMORY
        throw(GraphBLASOutOfMemoryException())
    elseif info == GrB_INSUFFICIENT_SPACE
        throw(GraphBLASInsufficientSpaceException())
    elseif info == GrB_INDEX_OUT_OF_BOUNDS
        throw(GraphBLASIndexOutOfBoundException())
    elseif info == GrB_PANIC
        throw(GraphBLASPanicException())
    end
end

function load_global(str)
    x = dlsym(graphblas_lib, str)
    return unsafe_load(cglobal(x, Ptr{Cvoid}))
end

function gbtype_from_jtype(T::DataType)
    return load_global("GrB_" * suffix(T))
end
