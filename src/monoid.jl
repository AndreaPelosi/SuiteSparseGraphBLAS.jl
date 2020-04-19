Base.push!(m::Monoid, items...) = push!(m.ops, items...)

# create new monoid from binary operation and identity value
function monoid(s::Symbol, bin_op::BinaryOperator, identity::T) where T <: valid_types
    domain = j2gtype(T)
    monoid = get!(Monoids, s, Monoid())
    index = findfirst(m->m.domain == domain, monoid.ops)
    if index == nothing
        bop = get_binaryop(bin_op, domain, domain, domain)
        grb_monoid = GrB_Monoid_new(bop, identity)
        push!(monoid, grb_monoid)
    else
        error("monoid already exists")
    end
    return monoid
end

function load_builtin_monoid()

    function load(lst)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype(string(bpn[end]))
            
            monoid_name = Symbol(join(bpn[2:end - 1]))
            monoid = get!(Monoids, monoid_name, Monoid())
            push!(monoid, GrB_Monoid(op, type))
        end
    end

    grb_mon = compile(["GrB"],
    ["MIN", "MAX", "PLUS", "TIMES"],
    ["BOOL", "UINT8", "UINT16", "UINT32", "UINT64", "INT8", "INT16", "INT32", "INT64", "FP32", "FP64"])

    grb_mon_bool = compile(["GxB"],
    ["LOR", "LAND", "LXOR", "ISEQ"],
    ["BOOL"])

    load(cat(grb_mon, grb_mon_bool, dims = 1))
        
end

function GrB_Monoid_new(binary_op::GrB_BinaryOp, identity::T) where T
    monoid = GrB_Monoid()
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