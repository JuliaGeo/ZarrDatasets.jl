
CDM.name(v::ZarrDataset) = Zarr.zname(v.zgroup)
Base.keys(ds::ZarrDataset) = keys(ds.zgroup.arrays)
Base.haskey(ds::ZarrDataset,varname::SymbolOrString) = haskey(ds.zgroup.arrays,String(varname))

function CDM.variable(ds::ZarrDataset,varname::SymbolOrString)
    zarray = ds.zgroup.arrays[String(varname)]
    ZarrVariable{eltype(zarray),ndims(zarray),typeof(zarray),typeof(ds)}(zarray,ds)
end

CDM.dimnames(ds::ZarrDataset) = Tuple(
    sort(
        unique(
            reduce(vcat,
                   (collect(dimnames(variable(ds,vn))) for vn in keys(ds)),
                   init = String[]
                   ))))

# function CDM.unlimited(ds::ZarrDataset)
#     ul = ds.unlimited
#     if ds.parentdataset != nothing
#         append!(ul,unlimited(ds.parentdataset))
#     end
#     return ul
# end

# function _dim(ds::ZarrDataset,dimname::SymbolOrString)
#     if haskey(ds.dimensions,name)
#         return ds.dimensions[name]
#     elseif ds.parentdataset !== nothing
#         return _dim(ds.parentdataset,name)
#     end
#     return nothing
# end

function CDM.dim(ds::ZarrDataset,dimname::SymbolOrString)

    for vn in keys(ds)
        v = variable(ds,vn)
        dn = dimnames(v)
        i = findfirst(==(dimname),dn)
        if !isnothing(i)
            return size(v,i)
        end
    end
    error("dimension $dimname not found")
end

CDM.varnames(ds::ZarrDataset) = keys(ds.zgroup.arrays)

CDM.attribnames(ds::ZarrDataset) = keys(ds.zgroup.attrs)
CDM.attrib(ds::ZarrDataset,name::SymbolOrString) = ds.zgroup.attrs[String(name)]


CDM.groupnames(ds::ZarrDataset) = keys(ds.zgroup.groups)
CDM.group(ds::ZarrDataset,name::SymbolOrString) = ZarrDataset(ds.zgroup.groups,String(name),ds)


CDM.parentdataset(ds::ZarrDataset) = ds.parentdataset
CDM.iswritable(ds::ZarrDataset) = false
CDM.maskingvalue(ds::ZarrDataset) = ds.maskingvalue


"""
    ds = ZarrDataset(url::AbstractString,mode = "r";
                     _omitcode = 404,
                     maskingvalue = missing)
    ZarrDataset(f::Function,url::AbstractString,mode = "r";
                     maskingvalue = missing)

Open the zarr dataset at the url or path `url`. Only the read-mode is
currently supported. `ds` supports the API of the
[JuliaGeo/CommonDataModel.jl](https://github.com/JuliaGeo/CommonDataModel.jl).
The experimental `_omitcode` allows to work-around servers that return
HTTP error different than 404 for missing chunks.

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
function ZarrDataset(url::AbstractString,mode = "r";
                     parentdataset = nothing,
                     _omitcode = 404,
                     maskingvalue = missing)
    ds = Zarr.zopen(url,mode)
    if ds.storage isa Zarr.HTTPStore
        Zarr.missing_chunk_return_code!(ds.storage,_omitcode)
    end
    ZarrDataset(ds,parentdataset,maskingvalue)
end


ZarrDataset(fnames::AbstractArray{<:AbstractString,N}, args...; kwargs...) where N =
    MFDataset(ZarrDataset,fnames, args...; kwargs...)


function ZarrDataset(f::Function,args...; kwargs...)
    ds = ZarrDataset(args...; kwargs...)
    try
        f(ds)
    finally
        close(ds)
    end
end
