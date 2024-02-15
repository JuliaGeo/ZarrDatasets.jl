
Base.getindex(v::ZarrVariable,ij...) = v.zarray[ij...]
CDM.load!(v::ZarrVariable,buffer,ij...) = buffer .= view(v.zarray,ij...)

function Base.setindex!(v::ZarrVariable,data,ij...)
    v.zarray[ij...] = data
end
Base.size(v::ZarrVariable) = size(v.zarray)
CDM.name(v::ZarrVariable) = Zarr.zname(v.zarray)
CDM.dimnames(v::ZarrVariable) = Tuple(reverse(v.zarray.attrs["_ARRAY_DIMENSIONS"]))
CDM.dataset(v::ZarrVariable) = v.parentdataset

CDM.attribnames(v::ZarrVariable) = filter(!=("_ARRAY_DIMENSIONS"),keys(v.zarray.attrs))
CDM.attrib(v::ZarrVariable,name::SymbolOrString) = v.zarray.attrs[String(name)]


# DiskArray methods
eachchunk(v::ZarrVariable) = eachchunk(v.zarray)
haschunks(v::ZarrVariable) = haschunks(v.zarray)
eachchunk(v::CFVariable{T,N,<:ZarrVariable}) where {T,N} = eachchunk(v.var)
haschunks(v::CFVariable{T,N,<:ZarrVariable}) where {T,N} = haschunks(v.var)
