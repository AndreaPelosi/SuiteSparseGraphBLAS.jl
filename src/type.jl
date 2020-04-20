const valid_types = Union{Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64}

struct GType{T <: Union{valid_types,Nothing}}
    jtype::DataType
    gbtype::Ptr{Cvoid}
    one::T
    zero::T
    name::String
end

Base.show(io::IO, T::GType) = print(io, T.name)

function load_gbtypes()
    union2lst(T) = if isa(T, Union) return push!(union2lst(T.b), T.a) else return [T] end

    function load_type(name, jtype, gbtype)
        if gbtype == C_NULL
            expression = "$name = GType{$jtype}($jtype, C_NULL, nothing, nothing, \"$name\"); export $name"
        else
            expression = "$name = GType{$jtype}($jtype, load_global(\"GrB_$gbtype\"), one($jtype), zero($jtype), \"$name\"); export $name"
        end
        eval(Meta.parse(expression))
    end

    for t in union2lst(valid_types)
        load_type(suffix(t), t, suffix(t))
    end
    load_type("NULL", Nothing, C_NULL)
end

function suffix(T::DataType)
    if T == Bool
        return "BOOL"
    elseif T == Int8
        return "INT8"
    elseif T == UInt8
        return "UINT8"
    elseif T == Int16
        return "INT16"
    elseif T == UInt16
        return "UINT16"
    elseif T == Int32
        return "INT32"
    elseif T == UInt32
        return "UINT32"
    elseif T == Int64
        return "INT64"
    elseif T == UInt64
        return "UINT64"
    elseif T == Float32
        return "FP32"
    else
        return "FP64"
    end
end

function jtype(T::String)
    if T == "BOOL"
        return Bool
    elseif T == "INT8"
        return Int8
    elseif T == "UINT8"
        return UInt8
    elseif T == "INT16"
        return Int16
    elseif T == "UINT16"
        return UInt16
    elseif T == "INT32"
        return Int32
    elseif T == "UINT32"
        return UInt32
    elseif T == "INT64"
        return Int64
    elseif T == "UINT64"
        return UInt64
    elseif T == "FP32"
        return Float32
    else
        return Float64
    end
end

function str2gtype(T::String)
    if T == "BOOL"
        return BOOL
    elseif T == "INT8"
        return INT8
    elseif T == "UINT8"
        return UINT8
    elseif T == "INT16"
        return INT16
    elseif T == "UINT16"
        return UINT16
    elseif T == "INT32"
        return INT32
    elseif T == "UINT32"
        return UINT32
    elseif T == "INT64"
        return INT64
    elseif T == "UINT64"
        return UINT64
    elseif T == "FP32"
        return FP32
    else
        return FP64
    end
end

function j2gtype(T)
    return str2gtype(suffix(T))
end