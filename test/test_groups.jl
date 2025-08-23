using ZarrDatasets
using Test

data = rand(Int32, 3, 5)
data2 = rand(Int8, 3, 5)
data3 = rand(Int16, 4)

fname = tempname()
mkdir(fname)

TDS = ZarrDataset

#using NCDatasets
#TDS = NCDataset
ds = TDS(fname, "c")
defDim(ds, "lon", 3)
defDim(ds, "lat", 5)

attrib = Dict("units" => "m/s", "long_name" => "test")

varname = "var2"
dimensionnames = ("lon", "lat")
vtype = Int32

zv = defVar(ds, varname, vtype, dimensionnames; attrib=attrib)
zv[:, :] = data
zv.attrib["number"] = 12
ds.attrib["history"] = "test"

group_name = "sub-group"
attrib = Dict("int_attrib" => 42)

dsg = defGroup(ds, group_name; attrib=attrib)

defDim(dsg, "time", length(data3))

zvg = defVar(dsg, "data2", eltype(data2), ("lon", "lat"))
zvg[:, :] = data2
zvg.attrib["standard_name"] = "test"

zv3 = defVar(dsg, "data3", eltype(data3), ("time",))
zv3[:] = data3

@test_throws Exception defVar(dsg, "data4", Int8, ("dimension_does_not_exists",))

io = IOBuffer()
show(io, ds)
s = String(take!(io))
@test occursin("sub-group", s)

close(ds)

# load data from group

ds = TDS(fname, "r")

@test ds["var2"][:, :] == data
@test ds.group[group_name]["data2"][:, :] == data2
@test ds.group[group_name]["data2"].attrib["standard_name"] == "test"
@test ds.group[group_name]["data3"][:] == data3

@test ds.group[group_name].attrib["int_attrib"] == 42

display(ds)
close(ds)
