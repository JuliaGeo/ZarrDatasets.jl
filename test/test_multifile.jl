using CommonDataModel:
    iswritable,
    attribnames,
    parentdataset,
    load!,
    dataset
using Dates
using DiskArrays
using NCDatasets
using Test
using ZarrDatasets


fnames = [tempname(), tempname()]
v = randn(2, 3, length(fnames))

nczarr_names = ["file://" * fname * "#mode=zarr" for fname in fnames]

for i = 1:length(fnames)
    local ds
    mkpath(fnames[i])
    ds = NCDataset(nczarr_names[i], "c")
    defVar(ds, "var", v[:, :, i:i], ("lon", "lat", "time"), attrib=Dict(
        "foo" => "bar",
        "int_attribute" => 1,
        "float_attribute" => 1.0,
        "scale_factor" => 1.23))
    ds.attrib["title"] = "test file"
    close(ds)
end

ds = NCDataset(nczarr_names, aggdim="time")
dsz = ZarrDataset(fnames, aggdim="time")

@test Set(dimnames(dsz)) == Set(dimnames(ds))

for (name, len) in ds.dim
    @test dsz.dim[name] == len
end

for (varname, v) in ds
    @test haskey(dsz, varname)

    v2 = dsz[varname]
    @test Array(v2) == Array(v)

    for (attribname, attribval) in v.attrib
        @test v2.attrib[attribname] == attribval
    end
end

for (attribname, attribval) in ds.attrib
    @test dsz.attrib[attribname] == attribval
end

io = IOBuffer()
show(io, dsz)
str = String(take!(io))
@test occursin("title", str)

@test !iswritable(dsz)
@test "title" in attribnames(dsz)

@test isnothing(parentdataset(dsz))

zvar = ZarrDataset(fnames, aggdim="time") do ds3
    Array(ds3["var"])
end

@test zvar == Array(ds["var"])

v = dsz["var"].var
buffer = zeros(eltype(v), size(v))
load!(v, buffer, :, :, :)

@test buffer == Array(ds["var"].var)

@test dataset(dsz["var"]) == dsz
close(ds)
close(dsz)
