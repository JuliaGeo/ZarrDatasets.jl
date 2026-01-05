## ZarrDatasets

See the [documentation of JuliaGeo/CommonDataModel.jl](https://juliageo.org/CommonDataModel.jl/stable/) for the full documentation of the API. As a quick reference, here is an example how to create and read a Zarr file store as a quick reference.

### Create a Zarr file store

The following example create a Zarr file store in the directory `"/tmp/test-zarr"`:

```julia
using ZarrDatasets

# sample data
data = [i+j for i = 1:3, j = 1:5]

directoryname = "/tmp/test-zarr"
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
directoryname = "/tmp/test-zarr"
ds = ZarrDataset(directoryname)
data = ds["varname"][:,:]
data_units = ds["varname"].attrib["units"]
```


```@autodocs
Modules = [ZarrDatasets]
```

### Interoperability with Zarr.jl

Here is a example of how to create a dataset with Zarr.jl that can be read in ZarrDatasets.jl.
As in python-xarray, ZaraDatasets.jl assume that there is a `_ARRAY_DIMENSIONS` attribute containing a list of the dimension names.
Note that Zarr.jl uses the C-ordering per default (for compatability with python). Therefore if an array has e.g. the dimensions lon x lat,
the corresponding `_ARRAY_DIMENSIONS` attribute is  `("lat","lon")`.

```julia
using Zarr
using ZarrDatasets
using Test

# your file name
fname = tempname()

# sample data (lon x lat)
data = rand(100,101)

store = Zarr.DirectoryStore(fname)
zg = zgroup(store)

# create a variable with the name "temp" where the
# first dimension in lon and the second dimension is lat
z = zcreate(Float64,zg,"temp",size(data)...;
            fill_value = 9999, # optional
            attrs = Dict("_ARRAY_DIMENSIONS" => ("lat","lon"))) # important
z .= data

# read data
ds = ZarrDataset(fname)

# output
#  temp   (100 × 101)
#    Datatype:    Union{Missing, Float64} (Float64)
#    Dimensions:  lon × lat
#    Attributes:
#     _FillValue           = 9999.0


data2 = ds["temp"][:,:]

@test data == data2
```


### Differences between Zarr and NetCDF files

* All metadata (in particular attributes) is stored in JSON files for the Zarr format with the following implications:
   * JSON does not distinguish between integers and real numbers. They are all considered as generic numbers. Whole numbers are loaded as `Int64` and real numbers `Float64`. It is not possible to store the number `1.0` as a real number.
   * The order of keys in a JSON document is undefined. It is therefore not possible to have a consistent ordering of the attributes or variables.
   * The JSON standard does not allow the values NaN, +Inf, -Inf which is problematic for attributes ([zarr-python #412](https://github.com/zarr-developers/zarr-python/issues/412),   [zarr-specs #81](https://github.com/zarr-developers/zarr-specs/issues/81)). However, there is a special case for the fill-value to handle NaN, +Inf and -Inf.
* All dimensions must be associated to Zarr variables.
