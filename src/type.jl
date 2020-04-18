struct GType
    jtype::DataType
    gbtype::Ptr{Cvoid}
    name::String
end

Base.show(io::IO, T::GType) = print(io, T.name)

const valid_types = (:BOOL, :INT8, :INT16, :INT32, :INT64, :UINT8, :UINT16, :UINT32, :UINT64, :FP32, :FP64, :ALL)

function load_gbtypes()
    for t in valid_types
        expression = "$t = GType(jtype(\"$t\"), load_global(\"GrB_$t\"), \"$t\")" 
        eval(Meta.parse(expression))
        eval(:(export $t))
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
    elseif T == "FP64"
        return Float64
    else
        return Nothing
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
    elseif T == "FP64"
        return FP64
    else
        return ALL
    end
end