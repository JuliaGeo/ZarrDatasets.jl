using ZarrDatasets
using Test
using Zarr

# Test opening a ZarrDataset using a pre-existing Zarr store or group

# First, 
fname = tempname()
mkdir(fname)
gattrib = Dict("title" => "this is the title")
ds = ZarrDataset(fname,"c",attrib = gattrib)

ds.attrib["number"] = 1
defDim(ds,"lon",3)
defDim(ds,"lat",5)

attrib = Dict(
    "units" => "m/s",
    "long_name" => "test",
)


varname = "var2"
dimensionnames = ("lon","lat")
vtype = Int32

zv = defVar(ds,varname,vtype,dimensionnames, attrib = attrib)
zv[:,:] = data = rand(Int32,3,5)

zv.attrib["number"] = 12
zv.attrib["standard_name"] = "test"
ds.attrib["history"] = "test"
close(ds)

for ds in ZarrDataset.((Zarr.storefromstring(fname)[1], Zarr.zopen(fname), ))

    zv = ds[varname]

    @test zv.attrib["number"] == 12
    @test zv.attrib["standard_name"] == "test"
    @test ds.attrib["history"] == "test"

    @test zv[:,:] == data

    io = IOBuffer()
    show(io,ds)
    str = String(take!(io))
    @test occursin("Global",str)
end
