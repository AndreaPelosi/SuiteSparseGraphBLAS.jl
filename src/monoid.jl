# create new monoid from binary operation and identity value
function monoid(s::Symbol, bin_op::BinaryOperator, identity::T) where T <: valid_types
    domain = j2gtype(T)
    monoid = get!(Monoids, s, Monoid())
    index = findfirst(mon -> mon.domain == domain, monoid.impl)
    if index == nothing
        # create a new monoid
        bop = _get(bin_op, domain, domain, domain)
        mon = GrB_Monoid_new(bop, identity)
        push!(monoid.impl, mon)
    end
    return monoid
end

function _get(monoid::Monoid, types...)
    (domain,) = types
    index = findfirst(mon -> mon.domain == domain, monoid.impl)
    if index == nothing
        error("monoid not find")
    end
    return monoid.impl[index]
end

function load_builtin_monoid()

    function load(lst)
        for op in lst
            bpn = split(op, "_")
            type = str2gtype(string(bpn[end-1]))
            
            monoid_name = Symbol(join(bpn[2:end-2], "_"))
            monoid = get!(Monoids, monoid_name, Monoid())
            push!(monoid.impl, GrB_Monoid(op, type))
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
    monoid = GrB_Monoid()
    monoid.domain = j2gtype(T)

    monoid_ptr = pointer_from_objref(monoid)
    fn_name = "GrB_Monoid_new_" * suffix(T)

    check(
        ccall(
            dlsym(graphblas_lib, fn_name),
            Cint,
            (Ptr{Cvoid}, Ptr{Cvoid}, Cintmax_t),
            monoid_ptr,
            _gb_pointer(binary_op),
            identity
            )
        )
    return monoid
end