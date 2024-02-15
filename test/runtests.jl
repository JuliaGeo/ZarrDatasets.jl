using Dates
using NCDatasets
using Test
using ZarrDatasets

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
    ds2 = ZarrDataset(fname)

    @test Set(dimnames(ds2)) == Set(dimnames(ds))

    for (name,len) in ds.dim
        @test ds2.dim[name] == len
    end

    for (varname,v) in ds
        @test haskey(ds2,varname)

        v2 = ds2[varname]
        @test Array(v2) == Array(v)

        for (attribname,attribval) in v.attrib
            @test v2.attrib[attribname] == attribval
        end
    end

    for (attribname,attribval) in ds.attrib
        @test ds2.attrib[attribname] == attribval
    end

    close(ds)
    close(ds2)
end
