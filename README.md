# ZarrDatasets

[![Build Status](https://github.com/JuliaGeo/ZarrDatasets.jl/workflows/CI/badge.svg)](https://github.com/JuliaGeo/ZarrDatasets.jl/actions)
[![codecov](https://codecov.io/github/JuliaGeo/ZarrDatasets.jl/graph/badge.svg?token=WuKAW6lYXn)](https://codecov.io/github/JuliaGeo/ZarrDatasets.jl)
[![documentation dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliageo.github.io/ZarrDatasets.jl/dev/)


ZarrDatasets.jl is a julia package to read [Zarr](https://zarr.dev/) datasets based on the native julia implementation [Zarr.jl](https://github.com/JuliaIO/Zarr.jl)
using the [CommonDataModel.jl](https://github.com/JuliaGeo/CommonDataModel.jl) interface.

In the following example, data from [Copernicus Marine Service](https://marine.copernicus.eu/) is loaded using `ZarrDatasets` and a subset
is saved as a NetCDF file:


```julia
using CommonDataModel: @select
using Dates
using NCDatasets
using STAC
using ZarrDatasets

# get the data set URL from product_id and dataset_id and the STAC catalog
function copernicus_marine_catalog(product_id,dataset_id,
    stac_url = "https://stac.marine.copernicus.eu/metadata/catalog.stac.json",
    asset = "timeChunked")

    cat = STAC.Catalog(stac_url);
    item_canditates = filter(startswith(dataset_id),collect(keys(cat[product_id].items)))
    # use last version per default
    dataset_version_id = sort(item_canditates)[end]
    item = cat[product_id].items[dataset_version_id]
    return href(item.assets[asset])
end

product_id = "MEDSEA_MULTIYEAR_PHY_006_004"
dataset_id = "med-cmcc-ssh-rean-d"

url = copernicus_marine_catalog(product_id,dataset_id)
ds = ZarrDataset(url);

# longitude, latitude and time are the coordinate variables defined in the
# zarr dataset
ds_sub = @select(ds, time == DateTime(2001,1,1)
    && 7 <= longitude <= 11
    && 42.3 <= latitude <= 44.5)

# save selection as a NetCDF file
NCDataset("$(dataset_id)_selection.nc","c") do ds_nc
    write(ds_nc,ds_sub)
end
```
