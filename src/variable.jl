# Base interface methods

function Base.getindex(
    v::ZarrVariable, ij::Union{Integer,Colon,AbstractVector{<:Integer}}...
)
    parent(v)[ij...]
end
function Base.setindex!(
    v::ZarrVariable, data, ij::Union{Integer,Colon,AbstractVector{<:Integer}}...
)
    parent(v)[ij...] = data
end
Base.size(v::ZarrVariable) = size(parent(v))
Base.parent(v::ZarrVariable) = v.zarray

# DiskArrays.jl interface methods

eachchunk(v::ZarrVariable) = eachchunk(parent(v))
haschunks(v::ZarrVariable) = haschunks(parent(v))
eachchunk(v::CFVariable{T,N,<:ZarrVariable}) where {T,N} = eachchunk(v.var)
haschunks(v::CFVariable{T,N,<:ZarrVariable}) where {T,N} = haschunks(v.var)

# CommonDataModel.jl interface methods

CDM.load!(v::ZarrVariable, buffer, ij...) = buffer .= view(parent(v), ij...)
CDM.name(v::ZarrVariable) = Zarr.zname(parent(v))
CDM.dimnames(v::ZarrVariable) = Tuple(reverse(parent(v).attrs["_ARRAY_DIMENSIONS"]))
CDM.dataset(v::ZarrVariable) = v.parentdataset

function CDM.attribnames(v::ZarrVariable)
    names = filter(!=("_ARRAY_DIMENSIONS"), keys(parent(v).attrs))
    if !isnothing(parent(v).metadata.fill_value) && !_iscoordvar(v)
        push!(names, "_FillValue")
    end
    return names
end

function CDM.attrib(v::ZarrVariable{T}, name::SymbolOrString) where {T}
    if String(name) == "_FillValue" && !isnothing(parent(v).metadata.fill_value)
        return T(parent(v).metadata.fill_value)
    end
    return parent(v).attrs[String(name)]
end

function CDM.defAttrib(v::ZarrVariable, name::SymbolOrString, value)
    @assert iswritable(dataset(v))
    @assert String(name) !== "_FillValue"

    parent(v).attrs[String(name)] = value

    storage = parent(v).storage
    io = IOBuffer()

    JSON.print(io, parent(v).attrs)
    storage[parent(v).path, ".zattrs"] = take!(io)
end

"""
    defVar(ds::ZarrDataset, name::SymbolOrString, vtype::DataType, dimensionnames; 
        chunksizes=nothing, attrib=Dict(), fillvalue=nothing)

Create a variable `name` in the dataset `ds` with the type 
`vtype` and the dimension `dimensionnames`.

For coordinate variables, fill values will be used a background value of 
undefined chunks and not as missing value as coordinate variables cannot 
have the `_FillValues` in the CF convension as in Zarr v2 format a `fill_value` 
does not necessarily indicate a missing value.

See also `CommonDataModel.defVar` for more information.
"""
function CDM.defVar(
    ds::ZarrDataset,
    name::SymbolOrString,
    vtype::DataType,
    dimensionnames;
    chunksizes=nothing,
    attrib=Dict(),
    fillvalue=nothing,
    kwargs...,
)
    @assert iswritable(ds)

    if isnothing(fillvalue)
        fillvalue = get(attrib, "_FillValue", nothing)
    end

    _attrib = Dict{String,Any}(attrib)
    _attrib["_ARRAY_DIMENSIONS"] = reverse(dimensionnames)

    _size = ntuple(length(dimensionnames)) do i
        _dim(ds, dimensionnames[i])
    end

    if isnothing(chunksizes)
        chunksizes = _size
    end

    zarray = zcreate(
        vtype,
        ds.zgroup,
        name,
        _size...;
        chunks=chunksizes,
        attrs=_attrib,
        fill_value=fillvalue,
        kwargs...,
    )

    return ds[name]
end

# Utility functions

function _iscoordvar(v)
    dn = dimnames(v)
    if length(dn) == 0
        return false
    end
    return name(v) == first(dn)
end
