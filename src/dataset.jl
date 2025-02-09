# Base interface

Base.keys(ds::ZarrDataset) = keys(ds.zgroup.arrays)
Base.haskey(ds::ZarrDataset, varname::SymbolOrString) = haskey(ds.zgroup.arrays, String(varname))

# CommonDataModel.jl interface

CDM.name(v::ZarrDataset) = Zarr.zname(v.zgroup)
function CDM.variable(ds::ZarrDataset, varname::SymbolOrString)
    zarray = ds.zgroup.arrays[String(varname)]
    ZarrVariable{eltype(zarray),ndims(zarray),typeof(zarray),typeof(ds)}(zarray, ds)
end
CDM.dimnames(ds::ZarrDataset) = Tuple(String.(keys(ds.dimensions)))
CDM.dim(ds::ZarrDataset, dimname::SymbolOrString) = ds.dimensions[Symbol(dimname)]
CDM.varnames(ds::ZarrDataset) = keys(ds.zgroup.arrays)
CDM.attribnames(ds::ZarrDataset) = keys(ds.zgroup.attrs)
CDM.attrib(ds::ZarrDataset, name::SymbolOrString) = ds.zgroup.attrs[String(name)]

# function CDM.unlimited(ds::ZarrDataset)
#     ul = ds.unlimited
#     if ds.parentdataset != nothing
#         append!(ul,unlimited(ds.parentdataset))
#     end
#     return ul
# end

function CDM.defDim(ds::ZarrDataset, dimname::SymbolOrString, dimlen)
    dn = Symbol(dimname)
    @assert !haskey(ds.dimensions, dn)
    ds.dimensions[dn] = dimlen
end

function CDM.defAttrib(ds::ZarrDataset, name::SymbolOrString, value)
    @assert iswritable(ds)
    ds.zgroup.attrs[String(name)] = value

    storage = ds.zgroup.storage
    io = IOBuffer()
    JSON.print(io, ds.zgroup.attrs)
    storage[ds.zgroup.path, ".zattrs"] = take!(io)
end

# groups
function CDM.defGroup(ds::ZarrDataset, groupname::SymbolOrString; attrib=Dict())
    _attrib = Dict{String,Any}(attrib)
    zg = zgroup(ds.zgroup, String(groupname), attrs=_attrib)
    dimensions = OrderedDict{Symbol,Int}()
    return ZarrDataset(ds, zg, dimensions, ds.iswritable, ds.maskingvalue)
end
CDM.groupnames(ds::ZarrDataset) = keys(ds.zgroup.groups)
function CDM.group(ds::ZarrDataset, groupname::SymbolOrString)
    dimensions = OrderedDict{Symbol,Int}()
    zg = ds.zgroup.groups[String(groupname)]
    return ZarrDataset(ds, zg, dimensions, ds.iswritable, ds.maskingvalue)
end

CDM.parentdataset(ds::ZarrDataset) = ds.parentdataset
CDM.iswritable(ds::ZarrDataset) = ds.iswritable
CDM.maskingvalue(ds::ZarrDataset) = ds.maskingvalue

"""
    ZarrDataset(url::AbstractString, mode = "r"; kw...)
    ZarrDataset(zg::Zarr.ZGroup; kw...)
    ZarrDataset(f::Function, url::AbstractString, mode = "r"; kw...)

Open the zarr dataset at the url or path `url`. The mode can only be `"r"` (read-only)
or `"c"` (create). `ds` supports the API of the
[JuliaGeo/CommonDataModel.jl](https://github.com/JuliaGeo/CommonDataModel.jl).

# Keywords

- `_omitcode`: *experimental*, allows to define which HTTP error code should be used
    for missing chunks. For compatibility with python's Zarr, the HTTP error 403
    (permission denied) is also used to missing chunks in addition to 404 (not
    found). Default [404, 403].
- `maskingvalue`: The parameter `maskingvalue` allows to define which special 
    value should be used as replacement for fill values. The default is `missing`.
    Defaults to `missing``.
- `attrib`: Attributes, defualts to `Dict()`

Example:

```julia
using ZarrDatasets
url = "https://s3.waw3-1.cloudferro.com/mdl-arco-time-035/arco/MEDSEA_MULTIYEAR_PHY_006_004/med-cmcc-ssh-rean-d_202012/timeChunked.zarr"
ds = ZarrDataset(url);
# see the metadata
display(ds)
# load the variable time
time = ds["time"][:]
# load the the attribute long_name for the variable zos
zos_long_name = ds["zos"].attrib["long_name"]
# load the global attribute
comment = ds.attrib["comment"]
# query the dimension of the variable zos
size(ds["zos"])
close(ds)
```

Example with a `do`-block:

```julia
using ZarrDatasets
url = "https://s3.waw3-1.cloudferro.com/mdl-arco-time-035/arco/MEDSEA_MULTIYEAR_PHY_006_004/med-cmcc-ssh-rean-d_202012/timeChunked.zarr"

zos1 = ZarrDataset(url) do ds
  ds["zos"][:,:,end,1]
end # implicit call to close(ds)
```
"""
function ZarrDataset(url::AbstractString, mode="r";
    parentdataset=nothing,
    _omitcode=[404, 403],
    maskingvalue=missing,
    attrib=Dict(),
)
    zg = if mode == "r"
        zg = Zarr.zopen(url, mode)
    elseif mode == "c"
        store = Zarr.DirectoryStore(url)
        zg = zgroup(store, "", attrs=Dict{String,Any}(attrib))
    end
    ZarrDataset(zg; mode, parentdataset, _omitcode, maskingvalue, attrib)
end
function ZarrDataset(store::Zarr.AbstractStore, mode="r";
    parentdataset=nothing,
    _omitcode=[404, 403],
    maskingvalue=missing,
    attrib=Dict(),
)
    return ZarrDataset(zopen(store, mode); mode, parentdataset, _omitcode, maskingvalue, attrib)
end
function ZarrDataset(zg::Zarr.ZGroup;
    mode="r",
    parentdataset=nothing,
    _omitcode=[404, 403],
    maskingvalue=missing,
    attrib=Dict(),
)
    dimensions = ZarrDatasets.OrderedDict{Symbol,Int}()
    if (zg.storage isa Zarr.HTTPStore) ||
       (zg.storage isa Zarr.ConsolidatedStore{Zarr.HTTPStore})
        @debug "omit chunks on HTTP error" _omitcode
        Zarr.missing_chunk_return_code!(zg.storage, _omitcode)
    end

    for (varname, zarray) in zg.arrays
        for (dimname, dimlen) in zip(reverse(zarray.attrs["_ARRAY_DIMENSIONS"]), size(zarray))
            dn = Symbol(dimname)
            if haskey(dimensions, dn)
                @assert dimensions[dn] == dimlen
            else
                dimensions[dn] = dimlen
            end
        end
    end

    return ZarrDataset(parentdataset, zg, dimensions, mode == "r" ? false : zg.writeable, maskingvalue)

end
ZarrDataset(fnames::AbstractArray{<:AbstractString,N}, args...; kwargs...) where {N} =
    MFDataset(ZarrDataset, fnames, args...; kwargs...)
function ZarrDataset(f::Function, args...; kwargs...)
    ds = ZarrDataset(args...; kwargs...)
    try
        f(ds)
    finally
        close(ds)
    end
end

function _dim(ds::ZarrDataset, dimname::SymbolOrString)
    dimlen = get(ds.dimensions, Symbol(dimname), nothing)

    if !isnothing(dimlen)
        return dimlen
    end

    if ds.parentdataset !== nothing
        return _dim(ds.parentdataset, dimname)
    end

    error("dimension $dimname is not defined")
end