using SuiteSparseGraphBLAS
SG = SuiteSparseGraphBLAS

function bfs(A, s)
    rowsA = size(A, 1)

    q = from_lists([s], [true], n = rowsA)
    visited = from_type(Int64, rowsA)
    desc = descriptor(SG.mask => SG.scmp, SG.outp => SG.replace)
    
    for l in 1:rowsA - 1
        @with q visited[:] = l
        vxm(q, A, out = q, semiring = Semirings.LOR_LAND, mask = visited, desc = desc)
        if !SG.reduce(q, monoid = Monoids.LOR)
            break
        end
    end

    return visited
end

A = from_matrix([0 1 0 1 0 0 0; 0 0 0 0 1 0 1; 0 0 0 0 0 1 0; 1 0 1 0 0 0 0 ; 0 0 0 0 0 1 0; 0 0 1 0 0 0 0; 0 0 1 1 1 0 0])
bfs(A, 1)