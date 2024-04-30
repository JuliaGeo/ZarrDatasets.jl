
## ZarrDatasets


See the [documentation of JuliaGeo/CommonDataModel.jl](https://juliageo.org/CommonDataModel.jl/stable/) for the full documentation of the API. As a quick reference, here is an example how to create and read a Zarr file store as a quick reference.

### Create a Zarr file store

The following example create a Zarr file store in the directory `"/tmp/test-zarr"`:

```julia
using ZarrDatasets

# sample data
data = [i+j for i = 1:3, j = 1:5]

directoryname = "/tmp/test-zarr4"
mkdir(directoryname)

ds = ZarrDataset(directoryname,"c")
defDim(ds,"lon",size(data,1))
defDim(ds,"lat",size(data,2))
zv = defVar(ds,"varname",Int64,("lon","lat"))
zv[:,:] = data
zv.attrib["units"] = "m"
close(ds)
```

### Loading a Zarr file store

The data and units can be loaded by indexing the data set structure `ds`.

```julia
using ZarrDatasets
directoryname = "/tmp/test-zarr4"
ds = ZarrDataset(directoryname)
data = ds["varname"][:,:]
data_units = ds["varname"].attrib["units"]
```



```@autodocs
Modules = [ZarrDatasets]
```





### Differences between Zarr and NetCDF files

* All metadata (in particular attributes) is stored in JSON files for the Zarr format with the following implications:
   * JSON does not distinguish between integers and real numbers. They are all considered as generic numbers. Whole numbers are loaded as `Int64` and real numbers `Float64`. It is not possible to store the number `1.0` as a real number.
   * The order of keys in a JSON document is undefined. It is therefore not possible to have a consistent ordering of the attributes or variables.
   * The JSON standard does not allow the values NaN, +Inf, -Inf which is problematic for attributes ([zarr-python #412](https://github.com/zarr-developers/zarr-python/issues/412),   [zarr-specs #81](https://github.com/zarr-developers/zarr-specs/issues/81)). However, there is a special case for the fill-value to handle NaN, +Inf and -Inf.
   * All dimensions must be associated to Zarr variables.
