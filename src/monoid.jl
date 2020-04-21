# create new monoid from binary operation and identity value
function monoid(s::Symbol, bin_op::BinaryOperator, identity::T) where T <: valid_types
    domain = j2gtype(T)
    if haskey(Monoids, s)
        error("monoid already exists")
    end
    bop = get_binaryop(bin_op, domain, domain, domain)
    monoid = GrB_Monoid_new(bop, identity)
    push!(Monoids, s => monoid)
    return monoid    
end

function load_builtin_monoid()

    function load(lst)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype(string(bpn[end-1]))
            
            monoid_name = Symbol(join(bpn[2:end-1], "_"))
            monoid = Monoid(op, type)
            push!(Monoids, monoid_name => monoid)
        end
    end

    grb_mon = compile(["GxB"],
    ["MIN", "MAX", "PLUS", "TIMES"],
    ["UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"],
    ["MONOID"])

    grb_mon_bool = compile(["GxB"],
    ["LOR", "LAND", "LXOR", "EQ"],
    ["BOOL"],
    ["MONOID"])

    load(cat(grb_mon, grb_mon_bool, dims = 1))
        
end

function GrB_Monoid_new(binary_op::GrB_BinaryOp, identity::T) where T
    monoid = Monoid()
    monoid.domain = j2gtype(T)

    monoid_ptr = pointer_from_objref(monoid)
    fn_name = "GrB_Monoid_new_" * suffix(T)

    check(GrB_Info(ccall(dlsym(
        graphblas_lib, fn_name),
        Cint,
        (Ptr{Cvoid}, Ptr{Cvoid}, Cintmax_t),
        monoid_ptr,
        binary_op.p,
        identity)
        )
    )
    return monoid
end