using Dates
using NCDatasets
using Test
using ZarrDatasets
using CommonDataModel: iswritable, attribnames, parentdataset

@testset "ZarrDatasets.jl" begin
    #fname = "/tmp/foo.zarr"
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

    @test zvar == Array(ds["var"])
    close(ds)
    close(dsz)
end
