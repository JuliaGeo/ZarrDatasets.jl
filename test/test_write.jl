using Test
using CommonDataModel: cfvariable
using ZarrDatasets
using ZarrDatasets: defDim, defVar

data = rand(Int32, 3, 5)

for zarr_format in (2, 3)
    @testset "Write Zarr format $zarr_format" begin
        fname = tempname()
        mkdir(fname)
        gattrib = Dict("title" => "this is the title")
        ds = ZarrDataset(fname, "c"; attrib=gattrib, zarr_format)

        ds.attrib["number"] = 1
        defDim(ds, "lon", 3)
        defDim(ds, "lat", 5)

        attrib = Dict("units" => "m/s", "long_name" => "test")

        varname = "var2"
        dimensionnames = ("lon", "lat")
        vtype = Int32

        zv = defVar(ds, varname, vtype, dimensionnames; attrib=attrib)
        zv[:, :] = data
        zv.attrib["number"] = 12
        zv.attrib["standard_name"] = "test"
        ds.attrib["history"] = "test"
        close(ds)

        ds = ZarrDataset(fname)

        zv = ds[varname]

        @test zv.attrib["number"] == 12
        @test zv.attrib["standard_name"] == "test"
        @test ds.attrib["history"] == "test"
        @test ds.dim["lon"] == 3
        @test ds.dim["lat"] == 5
        @test ZarrDatasets.dimnames(zv) == dimensionnames

        @test zv[:, :] == data

        io = IOBuffer()
        show(io, ds)
        str = String(take!(io))
        @test occursin("Global", str)

        # fill value

        fname = tempname()
        ds = ZarrDataset(fname, "c"; zarr_format)
        defDim(ds, "lon", 100)
        lon = defVar(ds, "lon", Float32, ("lon",); fillvalue=9999.0)
        lon .= 1
        close(ds)

        ds = ZarrDataset(fname)
        @test eltype(ds["lon"]) == Float32
        @test eltype(cfvariable(ds, "lon", fillvalue=nothing)) == Float32
    end
end