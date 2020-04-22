@testset "Vector" begin

    # from_type method
    for t in valid_types
        type = SG.j2gtype(t)
        vector_type = SG.vector_from_type(type, 10)
        @test vector_type.type == type
        @test SG.size(vector_type) == 10
        I, X = SG.findnz(vector_type)
        @test isempty(I) && isempty(X)
    end


end
