
## ZarrDatasets

```@autodocs
Modules = [ZarrDatasets]
```


### Differences between Zarr and NetCDF files

* All metadata (in particular attributes) is stored in JSON files for the Zarr format with the following implications:
   * JSON does not distinguish between integers and real numbers. They are all considered as generic numbers. Whole numbers are loaded as `Int64` and decimal numbers `Float64`. It is not possible to store the number `1.0` as a real number.
   * The order of keys in a JSON document is undefined. It is therefore not possible to have a consistent ordering of the attributes or variables.
   * The JSON standard does not allow NaN, +Inf, -Inf (https://github.com/capnproto/capnproto/issues/261).
