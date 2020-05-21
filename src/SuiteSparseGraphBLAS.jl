module SuiteSparseGraphBLAS

using Libdl
using SuiteSparseGraphBLAS_jll: libgraphblas

include("utils.jl")
include("type.jl")
include("structures.jl")
include("descriptor.jl")
include("unaryop.jl")
include("binaryop.jl")
include("monoid.jl")
include("semiring.jl")
include("vector.jl")
include("matrix.jl")
# include("selector.jl")
include("object_methods/lib_matrix.jl")
include("object_methods/lib_vector.jl")
include("context_methods.jl")

const valid_matrix_mask_types = Union{GBMatrix,GType{Nothing}}
# const valid_vector_mask_types = Union{GrB_Vector, GType{Nothing}}
const valid_accum_types = Union{GrB_BinaryOp,GType{Nothing}}
# const valid_desc_types = Union{GrB_Descriptor, GrB_NULL_Type}

graphblas_lib = C_NULL

function __init__()
    global graphblas_lib = Libdl.dlopen(libgraphblas)
    
    load_gbtypes()
    load_builtin_unaryop()
    load_builtin_binaryop()
    load_builtin_monoid()
    load_builtin_semiring()
    # load_builtin_selectop()

    global g_operators = (unaryop = Unaryop.ABS,
                          binaryop = Binaryop.PLUS,
                          monoid = Monoids.PLUS,
                          semiring = Semirings.PLUS_TIMES)
    
end

export Unaryop, Binaryop, Monoids, Semirings#, Selectop

# Exceptions
export GraphBLASNoValueException,
       GraphBLASUninitializedObjectException,
       GraphBLASInvalidObjectException,
       GraphBLASNullPointerException,
       GraphBLASInvalidValueException,
       GraphBLASInvalidIndexException,
       GraphBLASDomainMismatchException,
       GraphBLASDimensionMismatchException,
       GraphBLASOutputNotEmptyException,
       GraphBLASOutOfMemoryException,
       GraphBLASInsufficientSpaceException,
       GraphBLASIndexOutOfBoundException,
       GraphBLASPanicException

end # end of module
