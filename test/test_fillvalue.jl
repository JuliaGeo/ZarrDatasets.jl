using ZarrDatasets
using Test
using Zarr

fname = tempname()
mkdir(fname)

# CF coordinate variable with Zarr fill_value set

store = Zarr.DirectoryStore(fname)
zg = zgroup(store, "")
zarray = zcreate(
    Int, zg, "lon", 3;
    fill_value=9999,
    attrs=Dict("_ARRAY_DIMENSIONS" => ("lon",)))

ds = ZarrDataset(fname)
@test eltype(ds["lon"]) == Int

fname = tempname()
mkdir(fname)

ds = ZarrDataset(fname, "c")

# variable which is not a CF coordinate variable
v2 = defVar(ds, "foo", Int, (), fillvalue=9999)
@test eltype(v2) == Union{Missing,Int}

v3 = defVar(ds, "bar", Int16[2, 3, 4], ("time",), fillvalue=9999)
@test eltype(v3) == Union{Missing,Int16}
close(ds)
