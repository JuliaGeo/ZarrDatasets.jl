
Base.getindex(v::ZarrVariable,ij::Union{Integer,Colon,AbstractVector{<:Integer}}...) = v.zarray[ij...]
CDM.load!(v::ZarrVariable,buffer,ij...) = buffer .= view(v.zarray,ij...)

function Base.setindex!(v::ZarrVariable,data,ij::Union{Integer,Colon,AbstractVector{<:Integer}}...)
    v.zarray[ij...] = data
end
Base.size(v::ZarrVariable) = size(v.zarray)
CDM.name(v::ZarrVariable) = Zarr.zname(v.zarray)
CDM.dimnames(v::ZarrVariable) = Tuple(reverse(v.zarray.attrs["_ARRAY_DIMENSIONS"]))
CDM.dataset(v::ZarrVariable) = v.parentdataset

function _iscoordvar(v)
    dn = dimnames(v)
    if length(dn) == 0
        return false
    end
    return name(v) == first(dn)
end

function CDM.attribnames(v::ZarrVariable)
    names = filter(!=("_ARRAY_DIMENSIONS"),keys(v.zarray.attrs))
    if !isnothing(v.zarray.metadata.fill_value) && !_iscoordvar(v)
        push!(names,"_FillValue")
    end
    return names
end

function CDM.attrib(v::ZarrVariable{T},name::SymbolOrString) where T
    if String(name) == "_FillValue" && !isnothing(v.zarray.metadata.fill_value)
        return T(v.zarray.metadata.fill_value)
    end
    return v.zarray.attrs[String(name)]
end

function CDM.defAttrib(v::ZarrVariable,name::SymbolOrString,value)
    @assert iswritable(dataset(v))
    @assert String(name) !== "_FillValue"

    v.zarray.attrs[String(name)] = value

    storage = v.zarray.storage
    io = IOBuffer()
    JSON.print(io, v.zarray.attrs)
    storage[v.zarray.path,".zattrs"] = take!(io)
end


# DiskArray methods
eachchunk(v::ZarrVariable) = eachchunk(v.zarray)
haschunks(v::ZarrVariable) = haschunks(v.zarray)
eachchunk(v::CFVariable{T,N,<:ZarrVariable}) where {T,N} = eachchunk(v.var)
haschunks(v::CFVariable{T,N,<:ZarrVariable}) where {T,N} = haschunks(v.var)

"""

    defVar(ds::ZarrDataset,name::SymbolOrString,vtype::DataType,dimensionnames; chunksizes=nothing, attrib = Dict(), fillvalue = nothing)


Create a variable `name` in the dataset `ds` with the type `vtype` and the dimension `dimensionnames`.

For coordinate variables, fill values will be used a background value of undefined chunks and not as missing value as coordinate variables cannot have the `_FillValues` in the CF convension as in Zarr v2 format a `fill_value` does not necessarily indicate a missing value.

See also `CommonDataModel.defVar` for more information.
"""
function CDM.defVar(ds::ZarrDataset,name::SymbolOrString,vtype::DataType,dimensionnames; chunksizes=nothing, attrib = Dict(), fillvalue = nothing, kwargs...)
    @assert iswritable(ds)

    if isnothing(fillvalue)
        fillvalue = get(attrib,"_FillValue",nothing)
    end

    _attrib = Dict{String,Any}(attrib)
    _attrib["_ARRAY_DIMENSIONS"] = reverse(dimensionnames)

    _size = ntuple(length(dimensionnames)) do i
        _dim(ds,dimensionnames[i])
    end

    if isnothing(chunksizes)
        chunksizes = _size
    end

    zarray = zcreate(
        vtype, ds.zgroup, name, _size...;
        chunks = chunksizes,
        attrs = _attrib,
        fill_value = fillvalue,
        kwargs...
    )

    zv = ZarrVariable{vtype,ndims(zarray),typeof(zarray),typeof(ds)}(
        zarray,ds)

    return ds[name]
end
