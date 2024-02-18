using CommonDataModel:
    attribnames,
    dataset,
    iswritable,
    load!,
    parentdataset
using Dates
using DiskArrays
using NCDatasets
using Test
using ZarrDatasets


fname = tempname()
mkpath(fname)

nczarr_name = "file://" * fname * "#mode=zarr"
@debug "filenames " nczarr_name fname
v = randn(2,3)
ds = NCDataset(nczarr_name,"c")
defVar(ds,"var",v,("lon","lat"),attrib = Dict(
    "foo" => "bar",
    "int_attribute" => 1,
    "float_attribute" => 1.,
    "scale_factor" => 1.23))
ds.attrib["title"] = "test file"
close(ds)

ds = NCDataset(nczarr_name)
dsz = ZarrDataset(fname)

@test Set(dimnames(dsz)) == Set(dimnames(ds))

for (name,len) in ds.dim
    @test dsz.dim[name] == len
end

for (varname,v) in ds
    @test haskey(dsz,varname)

    v2 = dsz[varname]
    @test Array(v2) == Array(v)

    for (attribname,attribval) in v.attrib
        @test v2.attrib[attribname] == attribval
    end
end

for (attribname,attribval) in ds.attrib
    @test dsz.attrib[attribname] == attribval
end

io = IOBuffer()
show(io,dsz)
str = String(take!(io))
@test occursin("title",str)

@test !iswritable(dsz)
@test "title" in attribnames(dsz)
@test isnothing(parentdataset(dsz))

zvar = ZarrDataset(fname) do ds3
    Array(ds3["var"])
end

@test DiskArrays.haschunks(dsz["var"]) == DiskArrays.Chunked()
@test length(DiskArrays.eachchunk(dsz["var"])) ≥ 1
@test zvar == Array(ds["var"])

v = dsz["var"].var
buffer = zeros(eltype(v),size(v))
load!(v,buffer,:,:)

@test buffer == Array(ds["var"].var)

@test dataset(dsz["var"]) == dsz
close(ds)
close(dsz)
