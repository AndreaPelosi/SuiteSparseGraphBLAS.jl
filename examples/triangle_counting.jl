using SuiteSparseGraphBLAS


function cohen(A)
    B = mxm(LowerTriangular(A), UpperTriangular(A), mask=A)
    return Int64(reduce_scalar(B) // 2)
end

function sandia(A)
    L = LowerTriangular(A)
    return reduce_scalar(mxm(L, L, mask=L))
end

A = from_matrix([0 1 0 1 0 0 0; 1 0 0 1 1 0 1; 0 0 0 1 0 1 1; 1 1 1 0 0 1 1; 0 1 0 0 0 1 1; 0 0 1 1 1 0 0; 0 1 1 1 1 0 0])
@assert cohen(A) == sandia(A)